FROM alicek106/python-vim-devel:0.1
LABEL maintainer=alice_k106@naver.com

RUN git clone https://github.com/alicek106/k8s-admission-controller-python.git
WORKDIR /k8s-admission-controller-python
RUN  pip3 install -r requirements.txt
CMD ["python3", "/k8s-admission-controller-python/mutate-example.py"]