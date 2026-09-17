from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import Response
import pymysql
from datetime import datetime

app = FastAPI()

def connect():
    return pymysql.connect(
        host='127.0.0.1',
        user='root',
        password='qwer1234',
        database='todolist',
        charset='utf8'
    )

now = datetime.now()
formatted_date = now.strftime("%Y-%m-%d %H:%m:%S")

@app.post('/upload')
async def upload(
    content:str = Form(...),
    insertdate:str = formatted_date,
    file: UploadFile = File(...)
    ):

    try:
        image_data = await file.read()
        conn = connect()
        curs = conn.cursor()
        sql = """
                INSERT INTO todo
                (content,insertdate)
                VALUES (%s, %s)
            """
        sql2 = """
                INSERT INTO image
                (image)
                VALUES (%s)
            """
        curs.execute(sql,(content,insertdate))
        curs.execute(sql2,(image_data))
        conn.commit()
        conn.close()
        return {'result':'OK'}

    except Exception as e:
        print('Error:',e)
        return{'result':'Error'}

@app.get('/select')
async def select():
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT seq,content,insertdate FROM todo ORDER BY insertdate")
    todoRows = curs.fetchall()
    todoResult = [{'seq':row[0],'content':row[1],'insertdate':row[2]} for row in todoRows]
    #curs.execute("SELECT seq,image FROM image ORDER BY seq")
    #imageRows = curs.fetchall()
    #imageResult = [{'seq':row[0],'image':row[1],'insertdate':row[2]} for row in imageRows]
    conn.close()
    #result = [{'seq':row[0],'content':row[1],'insertdate':row[2]} for row in rows]
    return {'todoResult':todoResult}

@app.get('/view/{seq}')
async def view(seq:int):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute('SELECT image FROM image WHERE seq = %s',(seq,))
        row = curs.fetchone()
        #curs.commit() 커밋은 데이터 변형할때만
        conn.close()
        if row and row[0]:
            return Response(
                content=row[0],
                media_type='image/jpeg',
                headers={'Cache-Control':'no-cache, no-store, must-revalidate'}
            )
        else:
            return {'result':'No image found'}

    except Exception as e:
        print('Error',e)
        return{'result':'Error'}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app,host='192.168.10.39',port=8000)