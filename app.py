from flask import Flask, request, jsonify
import yaml
import json
import re

app = Flask(__name__)

@app.route("/convert", methods=["POST"])
def convert_yaml_to_json():
    try:
        yaml_content = request.data.decode("utf-8")
        
        # Configuration spécifique pour le parseur YAML pour gérer les références
        parsed_yaml = yaml.safe_load(yaml_content)
        
        # Traitement spécial pour les fichiers OpenAPI
        # Conversion en JSON compatible
        json_str = json.dumps(parsed_yaml, default=json_serializer)
        
        # Parsing du JSON pour s'assurer qu'il est valide
        json_obj = json.loads(json_str)
        
        return jsonify(json_obj)
    except yaml.YAMLError as e:
        return {"error": f"YAML parsing error: {str(e)}"}, 400
    except json.JSONDecodeError as e:
        return {"error": f"JSON serialization error: {str(e)}"}, 400
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}"}, 500

def json_serializer(obj):
    """Fonction personnalisée pour sérialiser des types non-JSON standards"""
    if isinstance(obj, (yaml.YAMLError, Exception)):
        return str(obj)
    # Ajoutez ici d'autres types spéciaux si nécessaire
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
