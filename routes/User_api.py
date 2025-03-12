from flask import Blueprint, request, jsonify
from db import get_db_connection

users_bp = Blueprint('users', __name__, url_prefix='/user')

# Obtener todos los usuarios
@users_bp.route('/', methods=['GET'])
def get_users():
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    conn.close()
    return jsonify(users), 200

# Obtener un usuario por ID
@users_bp.route('/<int:id>', methods=['GET'])
def get_user(id):
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE user_id = %s", (id,))
    user = cursor.fetchone()
    conn.close()
    return jsonify(user) if user else jsonify({"message": "User not found"}), 404

# Crear un nuevo usuario
@users_bp.route('/', methods=['POST'])
def create_user():
    data = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO users (first_name, last_name, email, phone, password_hash, user_type)
        VALUES (%s, %s, %s, %s, %s, %s)""",
        (data['first_name'], data['last_name'], data['email'], data.get('phone', None), data['password_hash'], data['user_type'])
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "User created successfully"}), 201

# Actualizar usuario
@users_bp.route('/<int:id>', methods=['PUT'])
def update_user(id):
    data = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """UPDATE users SET first_name=%s, last_name=%s, email=%s, phone=%s, password_hash=%s, user_type=%s
        WHERE user_id=%s""",
        (data['first_name'], data['last_name'], data['email'], data.get('phone', None), data['password_hash'], data['user_type'], id)
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "User updated successfully"}), 200 if cursor.rowcount else jsonify({"message": "User not found"}), 404

# Eliminar usuario
@users_bp.route('/<int:id>', methods=['DELETE'])
def delete_user(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM users WHERE user_id = %s", (id,))
    conn.commit()
    conn.close()
    return jsonify({"message": "User deleted successfully"}), 200 if cursor.rowcount else jsonify({"message": "User not found"}), 404
