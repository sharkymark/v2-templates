FROM sequenceiq/hadoop-docker:2.7.0

RUN apt-get update \
	&& apt-get install -y \
	curl \
	git \
	golang \
	sudo \
	vim \
	wget \
	openjdk-11-jdk \
	python3 \
	python3-pip \
	&& rm -rf /var/lib/apt/lists/*

# Install Jupyter
RUN pip3 install --upgrade pip && \
    pip3 install jupyter


# Configure Jupyter
RUN jupyter notebook --generate-config
RUN echo "c.NotebookApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py


# Expose ports
EXPOSE 8088 9870 8888

ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}
