import Player from "./player";

const Video = {
  init(socket, element) {
    if (!element) { return; }

    const playerId = element.dataset.playerId;
    const videoId = element.dataset.id;

    socket.connect();
    Player.init(element.id, playerId, () => {
      this.onReady(videoId, socket);
    });
  },

  onReady(videoId, socket) {
    const msgContainer = document.getElementById("msg-container");
    const msgInput = document.getElementById("msg-input");
    const msgSubmit = document.getElementById("msg-submit");
    const vidChannel = socket.channel("videos:" + videoId);

    msgSubmit.addEventListener("click", () => {
      const payload =  {body: msgInput.value, at: Player.getCurrentTime()};

      vidChannel.push("new_annotation", payload)
        .receive("error", e => console.log(e));
      msgInput.value = "";
    });

    vidChannel.on("new_annotation", resp => {
      vidChannel.params.last_seen_id = resp.id;
      this.renderAnnotation(msgContainer, resp);
    });

    vidChannel.join()
      .receive("ok", ({annotations}) => {
        const ids = annotations.map(ann => ann.id);
        if (ids.length) { vidChannel.params.last_seen_id = Math.max(...ids); }

        this.scheduleMessages(msgContainer, annotations);
      })
      .receive("error", reason => console.log("join failed", reason));

    msgContainer.addEventListener("click", e => {
      e.preventDefault();

      const time = e.target.dataset.seek || e.target.parentNode.dataset.seek;
      if (!time) { return; }

      Player.seekTo(time);
    });
  },

  esc(str) {
    const div = document.createElement("div");
    div.appendChild(document.createTextNode(str));

    return div.innerHTML;
  },

  renderAnnotation(msgContainer, {user, body, at}) {
    const template = document.createElement("div");

    template.innerHTML = `
      <a href="#" data-seek="${this.esc(at)}">
        [${this.formatTime(at)}]
        <b>${this.esc(user.username)}</b>: ${this.esc(body)}
     </a>`;

    msgContainer.appendChild(template);
    msgContainer.scrollTop = msgContainer.scrollHeight;
  },

  scheduleMessages(msgContainer, annotations) {
    setTimeout(() => {
      const time = Player.getCurrentTime();
      const remaining = this.renderAtTime(annotations, time, msgContainer);

      this.scheduleMessages(msgContainer, remaining);
    }, 1000);
  },

  renderAtTime(annotations, time, msgContainer) {
    return annotations.filter(ann => {
      if (ann.at > time) {
        return true;
      }
      else {
        this.renderAnnotation(msgContainer, ann);

        return false;
      }
    });
  },

  formatTime(at) {
    const date = new Date(null);
    date.setSeconds(at / 1000);

    return date.toISOString().substr(14, 5);
  }
};

export default Video;
