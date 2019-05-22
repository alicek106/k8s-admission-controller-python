from flask import Flask, request, jsonify
from pprint import pprint
import jsonpatch
import copy
import base64

app = Flask(__name__)


@app.route('/mutate', methods=['POST'])
def webhook():
    request_info = request.json
    request_info_object = request_info["request"]["object"]

    modified_info = copy.deepcopy(request_info)
    pprint(modified_info)
    modified_info_object = modified_info["request"]["object"]

    for container_spec in modified_info_object["spec"]["containers"]:
        print("Let's check port of {}/{}... \n".format(modified_info_object["metadata"]["name"], container_spec['name']))
        check_nginx_port(container_spec)

    patch = jsonpatch.JsonPatch.from_diff(request_info_object, modified_info_object)
    print("############## JSON Patch ############## ")
    pprint(str(patch))
    print('\n')

    admissionReview = {
        "response": {
            "allowed": True,
            "uid": request_info["request"]["uid"],
            "patch": base64.b64encode(str(patch).encode()).decode(),
            "patchtype": "JSONPatch"
        }
    }

    print("############## This data will be sent to k8s (admissionReview) ##############")
    pprint(admissionReview)
    print('\n')

    return jsonify(admissionReview)


def check_nginx_port(container_spec):
    image = container_spec["image"]
    port = container_spec['ports'][0]['containerPort']

    if 'nginx' in image and port != 80:
        print('Oh, alice specified nginx Docker image, but using port {}!'.format(port))
        container_spec['ports'][0]['containerPort'] = 80
        print('OK, alice\'s port is successfully changed to 80!\n\n')


app.run(host='0.0.0.0', debug=True, ssl_context=('/run/secrets/tls/tls.crt', '/run/secrets/tls/tls.key'))