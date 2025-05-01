from flask import Flask, request, jsonify
import yaml
import json

app = Flask(__name__)

@app.route("/convert", methods=["POST"])
def convert_yaml_to_json():
    try:
        yaml_content = request.data.decode("utf-8")
        parsed_yaml = yaml.safe_load(yaml_content)
        return jsonify(parsed_yaml)
    except yaml.YAMLError as e:
        return {"error": str(e)}, 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
