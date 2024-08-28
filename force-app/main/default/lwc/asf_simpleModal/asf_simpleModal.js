import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Asf_simpleModal extends LightningModal {
    @api content;
    @api header;
    @api footeraction;
    
    handleOkay() {
        this.close('okay');
    }
}