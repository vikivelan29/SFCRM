import { LightningElement,api } from 'lwc';
import getCommunicationLink from "@salesforce/apex/ABSLI_PolicyDynamicButtonsController.getCommunicationLink";


export default class ABSLI_redirectToCommLink extends LightningElement {
    @api recordId;

    async connectedCallback(){
        await getCommunicationLink({policyId : this.recordId})
        .then((result)=>{
            debugger;
            console.log(result);
            window.open(result, '_blank', 'noreferrer')
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