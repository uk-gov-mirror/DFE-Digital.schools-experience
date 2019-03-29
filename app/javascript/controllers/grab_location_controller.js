import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "latitude", "longitude", "location", "icon", "error-msg" ] ;
  currentLocationString = 'Using your current location' ;
  originalPlaceholder = 'currentLocationString' ;
  crossHairsIcon = 'fa-crosshairs' ;
  spinnerIcon = 'fa-refresh' ;
  spinIcon = 'fa-spin' ;
  timedOut = false ;
  locationSearchFinished = false ;
  timeOutLengthSeconds = 10 ;
  errorMessage = null ;

  connect() {
    if (this.enableGeolocation()) {
      this.addLocationLink() ;
      this.addInputFieldWrapper() ;
      this.toggleCoordsState() ;
    }

    this.showErrorMsg('Hello Jeremy') ;
  }

  isIE() {
    return (!!window.MSInputMethodContext && !!document.documentMode) ;
  }

  enableGeolocation() {
    return (("geolocation" in navigator) && !this.isIE()) ;
  }

  clearLocationInfo() {
    this.clearErrorMsg() ;

    if (this.latitudeTarget.value != '' || this.longitudeTarget != '' ||
      this.longitudeTarget.value == this.currentLocationString) {
        this.removeCoords() ;
    }
  }

  removeCoords() {
    this.latitudeTarget.value = '' ;
    this.longitudeTarget.value = '' ;
    this.toggleCoordsState() ;
  }

  setCoords(coords) {
    this.latitudeTarget.value = coords.latitude ;
    this.longitudeTarget.value = coords.longitude ;
    this.toggleCoordsState() ;
  }

  addLocationLink() {
    const inputId = this.locationTarget.getAttribute('id') ;
    const label = this.element.querySelectorAll('label[for="' + inputId + '"]')[0] ;

    if (!label)
      return ;

    const link = document.createElement('a') ;
    link.className = 'school-search-form__coords-request' ;
    link.setAttribute('href', '#') ;
    link.setAttribute('data-action', 'click->' + this.identifier + '#requestLocation') ;

    const txt = document.createTextNode("Use my location ") ;
    link.appendChild(txt) ;

    const icon = document.createElement('i') ;
    icon.className = 'fa fa-fw ' + this.crossHairsIcon ;
    icon.setAttribute('data-target', this.identifier + '.icon') ;
    link.appendChild(icon) ;

    label.parentNode.insertBefore(link, label) ;

    return link ;
  }

  addInputFieldWrapper() {
    const container = document.createElement('div') ;
    container.className = 'school-search-form__location-field-container' ;

    this.locationTarget.parentNode.appendChild(container) ;
    container.appendChild(this.locationTarget) ;
  }

  toggleCoordsState() {
    if (this.latitudeTarget.value != '' && this.longitudeTarget.value != '') {
      this.locationTarget.value = this.currentLocationString ;
      this.element.classList.add('school-search-form__location-field--using-coords') ;
    } else {
      this.latitudeTarget.value = '' ;
      this.longitudeTarget.value = '' ;

      if (this.locationTarget.value == this.currentLocationString) {
        this.locationTarget.value = '' ;
      }

      this.element.classList.remove('school-search-form__location-field--using-coords') ;
    }
  }

  requestLocation(ev) {
    ev.preventDefault() ;

    this.showSpinner() ;
    this.startTimeout() ;
    this.clearErrorMsg() ;

    if (this.enableGeolocation()) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          if (!this.timedOut) {
            this.locationSearchFinished = true ;
            this.setCoords(position.coords) ;
            this.hideSpinner() ;
          }
        },
        (err) => {
          this.locationSearchFinished = true ;
          this.locationUnavailable() ;
          this.hideSpinner() ;
        }
      ) ;
    }
  }

  startTimeout() {
    this.timedOut = false ;
    this.locationSearchFinished = false ;

    setTimeout(() => {
      if (!this.locationSearchFinished) {
        this.timedOut = true ;
        this.locationUnavailable("Location retrieval took too long") ;
      }
    }, this.timeOutLengthSeconds * 1000) ;
  }

  locationUnavailable(msg) {
    this.hideSpinner() ;
    this.showErrorMsg(msg || "Your location is not available") ;
  }

  showErrorMsg(msg) {
    if (!this.errorMessage) {
      this.errorMessage = document.createElement('div') ;
      this.errorMessage.setAttribute('class', 'grab-location--error-message') ;
      this.locationTarget.parentNode.appendChild(this.errorMessage) ;
    }

    this.errorMessage.innerHTML = msg ;
  }

  clearErrorMsg() {
    if (this.errorMessage)
      this.errorMessage.innerHTML = '' ;
  }

  showSpinner() {
    this.iconTarget.classList.remove(this.crossHairsIcon) ;
    this.iconTarget.classList.add(this.spinnerIcon) ;
    this.iconTarget.classList.add(this.spinIcon) ;
  }

  hideSpinner() {
    this.iconTarget.classList.remove(this.spinIcon) ;
    this.iconTarget.classList.remove(this.spinnerIcon) ;
    this.iconTarget.classList.add(this.crossHairsIcon) ;
  }
}
