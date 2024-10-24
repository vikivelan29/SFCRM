import { LightningElement, api } from 'lwc';

export default class ABHI_OmniDocViewAccordianForCase extends LightningElement {
    openSections = [];
    @api recordId;
    @api objectApiName;
    @api accordianName;
    isVisible = false;

    handleToggleSection() {
        this.isVisible = !this.isVisible;
    }
}