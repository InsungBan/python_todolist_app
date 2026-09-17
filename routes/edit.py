from fastapi import FastAPI, UploadFile, File, Form, HTTPException
import pymysql
from datetime import datetime

app = FastAPI()


def connect():
    return pymysql.connect(
        host='192.168.10.39',
        user='root',
        password='qwer1234',
        database='todolist',
        charset='utf8'
    )

@app.put("/update/{seq}")
async def update_todo(
    seq: int,
    context: str = Form(...),
    file: UploadFile | None = File(None), ):
    conn = None
    curs = None
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
            """
            SELECT seq
            FROM selected
            WHERE seq = %s
            """,
            (seq,),
        )
        if curs.fetchone() is None:
            raise HTTPException(
                status_code=404,
                detail='수정할 selected 데이터가 없습니다.',
            )
        todo_sql = """
            UPDATE todo AS t
            INNER JOIN selected AS s
                ON t.seq = s.todo_seq
            SET t.context = %s
            WHERE s.seq = %s
        """
        curs.execute(
            todo_sql,
            (context, seq),
        )
        if file is not None:
            if (
                file.content_type is None
                or not file.content_type.startswith('image/')
            ):
                raise HTTPException(
                    status_code=400,
                    detail='이미지 파일만 업로드할 수 있습니다.',
                )
            image_data = await file.read()
            image_sql = """
                UPDATE image AS i
                INNER JOIN selected AS s
                    ON i.seq = s.seq
                SET i.image = %s
                WHERE s.seq = %s
            """
            curs.execute(
                image_sql,
                (image_data, seq),
            )
        curs.execute(
            """
            UPDATE selected
            SET editdate = %s
            WHERE seq = %s
            """,
            (datetime.now(), seq),
        )
        conn.commit()
        return {
            'result': 'OK',
            'seq': seq,
        }
    except HTTPException:
        if conn is not None:
            conn.rollback()
        raise
    except Exception as e:
        if conn is not None:
            conn.rollback()
        print('Update Error:', e)
        return {
            'result': 'Error',
            'message': str(e),
        }
    finally:
        if curs is not None:
            curs.close()
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host='192.168.10.39',
        port=8000,
    )