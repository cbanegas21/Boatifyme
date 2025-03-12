from flask import Blueprint, request, jsonify
from db import get_db_connection

boats_bp = Blueprint('boats', __name__, url_prefix='/boat')

# Obtener todos los barcos
@boats_bp.route('/', methods=['GET']) 
def get_boats():
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM boats")
    boats = cursor.fetchall()
    conn.close()
    return jsonify(boats), 200

# Obtener un barco por ID
@boats_bp.route('/<int:boat_id>', methods=['GET'])
def get_boat(boat_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM boats WHERE boat_id = %s", (boat_id,))
    boat = cursor.fetchone()
    conn.close()
    return jsonify(boat) if boat else jsonify({"message": "Boat not found"}), 404

# Crear un nuevo barco
@boats_bp.route('/', methods=['POST'])
def create_boat():
    data = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO boats (owner_id, name, description, boat_type, capacity, base_price, currency, address, city, state, country, latitude, longitude)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
        (data['owner_id'], data['name'], data['description'], data['boat_type'], data['capacity'],
         data['base_price'], data['currency'], data['address'], data['city'], data['state'],
         data['country'], data['latitude'], data['longitude'])
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "Boat created successfully"}), 201

# Actualizar un barco
@boats_bp.route('/<int:boat_id>', methods=['PUT'])
def update_boat(boat_id):
    data = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """UPDATE boats SET owner_id=%s, name=%s, description=%s, boat_type=%s, capacity=%s, 
        base_price=%s, currency=%s, address=%s, city=%s, state=%s, country=%s, latitude=%s, longitude=%s
        WHERE boat_id=%s""",
        (data['owner_id'], data['name'], data['description'], data['boat_type'], data['capacity'],
         data['base_price'], data['currency'], data['address'], data['city'], data['state'],
         data['country'], data['latitude'], data['longitude'], boat_id)
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "Boat updated successfully"}), 200 if cursor.rowcount else jsonify({"message": "Boat not found"}), 404

# Eliminar un barco
@boats_bp.route('/<int:boat_id>', methods=['DELETE'])
def delete_boat(boat_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM boats WHERE boat_id = %s", (boat_id,))
    conn.commit()
    conn.close()
    return jsonify({"message": "Boat deleted successfully"}), 200 if cursor.rowcount else jsonify({"message": "Boat not found"}), 404
