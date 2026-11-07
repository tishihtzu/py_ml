
FROM quay.io/jupyter/scipy-notebook:latest

USER ${NB_UID}

RUN pip install --no-cache-dir \
    "tensorflow>=2.16" \
    "jax" \
    "keras>=3" \
    && pip check

ENV KERAS_BACKEND=tensorflow
