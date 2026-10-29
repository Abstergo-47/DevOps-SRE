ARG PYTHON_VERSION=3.14
FROM python:${PYTHON_VERSION}-alpine
WORKDIR /app

ENV PYTHONUNBUFFERED=1

# pip/setuptools are not needed at runtime and ship vulnerable vendored deps
RUN pip uninstall -y pip setuptools wheel 2>/dev/null; \
    rm -rf /usr/local/lib/python*/site-packages/pip* \
           /usr/local/lib/python*/site-packages/setuptools* \
           /usr/local/lib/python*/site-packages/pkg_resources* \
           /usr/local/bin/pip*

RUN adduser -D -u 1000 appuser
USER appuser

COPY --chown=appuser:appuser app/ .
EXPOSE 8080

CMD ["python", "app.py"]
