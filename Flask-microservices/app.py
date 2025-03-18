from flask import Flask
from routes.Boats_api import boats_bp  # Importación corregida
from routes.User_api import users_bp  # Importación corregida

app = Flask(__name__)

# Registrar los Blueprints
app.register_blueprint(users_bp)
app.register_blueprint(boats_bp)

if __name__ == '__main__':
    app.run(debug=True)
