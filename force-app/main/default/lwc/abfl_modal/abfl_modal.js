import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Abfl_modal extends LightningModal {
	@api templateId;
    @api assetId;

	handleOkay() {
        this.close('okay');
    }

    modalCloseHandler() {
        this.handleOkay();
    }
}