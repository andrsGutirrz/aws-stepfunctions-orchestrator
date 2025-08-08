FROM public.ecr.aws/lambda/python:3.12

# Install uv
RUN pip install uv

# Copy pyproject.toml
COPY pyproject.toml ${LAMBDA_TASK_ROOT}

# Install Python dependencies with uv
RUN cd ${LAMBDA_TASK_ROOT} && uv pip install --system -r pyproject.toml

# Copy function code
COPY handler.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD ["handler.lambda_handler"]