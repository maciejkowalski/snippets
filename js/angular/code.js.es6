/////////////////////////////////////////////////
// controller
/////////////////////////////////////////////////
import _ from 'underscore';
import Papa from 'papaparse';

class ReceivingController {
  constructor($http, $mdDialog, signature) {
    'ngInject';
    this.list = this.data = this.rawData = undefined;
    this.name = 'receiving';
    this.locationArray = // condifential =)
    this.courierArray = ['UPS', 'USPS', 'FedEX', 'DHL', 'BioCair', 'Marken', 'World Courier', 'unknown'];
    this.$mdDialog = $mdDialog;
    this.$http = $http;
    this.signature = signature;
    this._resetFormData();
    this.signature.activateCanvas();
  }

  queryRecipient(query) {
    if (_.isEmpty(query)) return;

    let result = _.filter(this.rawData, (x) => {
      return x.toLowerCase().indexOf(query.toLowerCase()) != -1;
    });
    this.recipientData = result;
    return result;
  }

  clearSignature(x) {
    this.signature.clearSignature();
  }

  _resetFormAndSignature(form) {
    this._resetFormData();
    form.$setPristine();
    form.$setUntouched();
    this.clearSignature();
  }

  _showMdDialogMessage(event) {
    this.$mdDialog.show(
      this.$mdDialog.alert()
        .parent(angular.element(document.querySelector('#popupContainer')))
        .clickOutsideToClose(true)
        .title(this.formStatus)
        .textContent(this.formMsg)
        .ariaLabel('Alert Dialog Demo')
        .ok('Got it!')
        .targetEvent(event)
    );
  }
  // [...]
}

export default ReceivingController;

/////////////////////////////////////////////////
// component declaration
/////////////////////////////////////////////////

import controller from './receiving.controller';
import template from './receiving.html';
import './receiving.scss';

let receivingComponent = {
  restrict: 'E',
  bindings: {},
  template,
  controller,
  controllerAs: "vm"
};

export default receivingComponent;
