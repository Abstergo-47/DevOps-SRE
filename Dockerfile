FROM python:3.14-alpine
WORKDIR /app

ENV PYTHONUNBUFFERED=1

RUN useradd appuser
USER appuser

COPY --chown=appuser:appuser app/ .
EXPOSE 8080

CMD ["python", "app.py"]
