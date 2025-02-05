import { LightningElement, api, track, wire } from 'lwc';
import getButtonsConfig from "@salesforce/apex/ASF_DynamicButtonsController.getButtonsConfig";



export default class ASF_DynamicButtons extends LightningElement {
    componentConstructor;
    @api recordId;
    @api objectApiName;

    @track processApexReturnValue;
    @track showModal=false;
    @track modalHeader = '';
    @track selectedButtonApexClass = '';

    @wire(getButtonsConfig, {
        "objApiName": "$objectApiName",
        "recId":"$recordId"
    })
    async processResult(result) {
        this.processApexReturnValue = result.data;
        console.log(this.processApexReturnValue);
    }

    async handleButtonClick(event){
        console.log(event);
        debugger;
        let compName = event.target.getAttribute('data-lwc-name');
        let evtlabel = event.target.getAttribute('data-lwc-header-name');
        let cls = event.target.getAttribute('data-apex-controller-name');
        console.log('compName --> '+compName);
        const { default: ctor } = await import(compName);
        this.componentConstructor = ctor;
        this.modalHeader = evtlabel;
        this.showModal = true;
        this.selectedButtonApexClass = cls;


    }
    handleCancel(event){
        this.modalHeader = "";
        this.componentConstructor=undefined;
        this.showModal = false;
    }
    handleSend(event){
        if (this.refs.myCmp) {
            console.log('Inside handleSend');
            console.log(this.refs.myCmp);
            this.refs.myCmp.sendCommunication(this.recordId);
          }
    }
    handleClosePopup(event){
        if(event.detail.message == true || event.detail.message == "true"){
            this.handleCancel();
        }
    }
    
}