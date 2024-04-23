import { LightningElement, api } from 'lwc';

export default class AbflMessageText extends LightningElement {
    @api odpData;
    showMore = false;

    updateview(){
        this.showMore = !this.showMore
    }

}