FROM ruby:3.1.3

RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get install -y imagemagick && \
    apt-get install -y build-essential && \
    apt-get install -y libmagic-dev && \
#    apt-get install -y libmagickwand-dev && \
    rm -rf /var/lib/apt/lists/*

RUN gem install activesupport \
    awesome_print \
    chunky_png \
    colored \
    exif \
#    debase \
    fastimage \
    highline \
    pry-byebug \
    phashion \
    puma \
    rackup \
    rerun \
    rmagick \
    rspec \
    ruby-filemagic \
#    ruby-debug-ide \
    russian \
    sinatra \
    streamio-ffmpeg \
    string_to_id


WORKDIR /app

COPY ./src /app

# Create a non-root user with an explicit UID
RUN useradd --no-log-init --uid 1000 appuser
RUN chown -R appuser:appuser /app

RUN mkdir -p /vt
RUN chown -R appuser:appuser /vt

CMD ["./info.sh"]
