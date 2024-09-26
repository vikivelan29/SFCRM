import { LightningElement, api } from 'lwc';
import generateLink from "@salesforce/apex/ABSLI_PolicyDynamicButtonsController.getReadyReckUrl";

export default class ABSLI_redirectToReadyReckenor extends LightningElement {
    @api recordId;

    async connectedCallback(){
        await generateLink({policyId : this.recordId})
        .then((result)=>{
            debugger;
            console.log(result);
            window.open(result);
            this.invokeCloseModal();
        })
        .catch((error)=>{
            debugger;
            console.log(error);

        })
    }
    async invokeCloseModal(){
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
}