import { LightningElement,api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Abhfl_assetdetailquickaction extends LightningElement {
    _recordId;
    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    closeModal(e){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}