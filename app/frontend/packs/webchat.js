function Webchat() {
  this.container = document.getElementById('app-web-chat')
  this.setupElements()
  this.addButtonListener()
  this.addStatusChangeListener()
}

Webchat.prototype.setupElements = function() {
  this.enabledContainer = document.createElement('span')
  this.button = document.createElement('a')
  this.button.href = '#'
  this.button.className = 'govuk-link govuk-footer__link app-web-chat__button'
  this.button.innerHTML = 'speak to an advisor now (opens in new window)'
  this.enabledContainer.append(this.button)

  this.disabledContainer = this.container.querySelector('.app-web-chat__offline')
}

Webchat.prototype.addButtonListener = function() {
  this.button.addEventListener('click', function(e) {
    e.preventDefault()

    zE('webWidget', 'popout');
  }, false)
}

Webchat.prototype.addStatusChangeListener = function() {
  zE('webWidget:on', 'chat:status', function(status) {
    if(status === 'online') {
      this.enableChat()
    } else  {
      this.disableChat()
    }
  }.bind(this));
}

Webchat.prototype.enableChat = function() {
  this.container.removeChild(this.disabledContainer)
  this.container.append(this.enabledContainer)
}

Webchat.prototype.disableChat = function() {
  this.container.removeChild(this.disabledContainer)
  this.container.append(this.enabledContainer)
}

const webchat = () => new Webchat()
export default webchat;
