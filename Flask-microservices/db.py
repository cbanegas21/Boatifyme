import mysql.connector
from mysql.connector import Error

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host='localhost',
            user='root',  # Reemplaza con tu usuario de MySQL
            password='2000',  # Reemplaza con tu contraseña
            database='boatifyme_db'
        )
        return conn
    except Error as e:
        print(f"Error al conectar a MySQL: {e}")
        return None
