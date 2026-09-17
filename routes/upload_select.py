from datetime import datetime

import pymysql
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import Response


app = FastAPI()


def connect():
    return pymysql.connect(
        host="127.0.0.1",
        user="root",
        password="qwer1234",
        database="todolist",
        charset="utf8",
    )


@app.post("/upload")
async def upload(
    content: str = Form(...),
    insertdate: str = Form(
        default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    ),
    file: UploadFile = File(...),
):
    conn = None
    try:
        image_data = await file.read()
        conn = connect()
        with conn.cursor() as curs:
            curs.execute(
                "INSERT INTO todo (content, insertdate) VALUES (%s, %s)",
                (content, insertdate),
            )
            curs.execute("INSERT INTO image (image) VALUES (%s)", (image_data,))
        conn.commit()
        return {"result": "OK"}
    except Exception as exc:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Upload failed") from exc
    finally:
        if conn is not None:
            conn.close()


@app.get("/select")
async def select():
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute("SELECT seq, content, insertdate FROM todo ORDER BY insertdate")
            rows = curs.fetchall()
        return {
            "todoResult": [
                {"seq": row[0], "content": row[1], "insertdate": row[2]}
                for row in rows
            ]
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Select failed") from exc
    finally:
        if conn is not None:
            conn.close()


@app.get("/view/{seq}")
async def view(seq: int):
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute("SELECT image FROM image WHERE seq = %s", (seq,))
            row = curs.fetchone()
        if row and row[0]:
            return Response(
                content=row[0],
                media_type="image/jpeg",
                headers={"Cache-Control": "no-cache, no-store, must-revalidate"},
            )
        raise HTTPException(status_code=404, detail="Image not found")
    finally:
        if conn is not None:
            conn.close()


@app.delete("/todos/{seq}")
async def delete_todo(seq: int):
    conn = None
    try:
        conn = connect()
        with conn.cursor() as curs:
            curs.execute("DELETE FROM todo WHERE seq = %s", (seq,))
            deleted_count = curs.rowcount

        if deleted_count == 0:
            conn.rollback()
            raise HTTPException(status_code=404, detail="Todo not found")

        conn.commit()
        return {"result": "OK"}
    except HTTPException:
        raise
    except Exception as exc:
        if conn is not None:
            conn.rollback()
        raise HTTPException(status_code=500, detail="Delete failed") from exc
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="192.168.10.39", port=8000)
