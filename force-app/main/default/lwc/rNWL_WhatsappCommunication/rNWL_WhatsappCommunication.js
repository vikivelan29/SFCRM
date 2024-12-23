import { LightningElement,api } from 'lwc';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import getData from'@salesforce/apex/RNWL_WhatsappCommunicationController.getData';

export default class RNWL_WhatsappCommunication extends LightningElement {
    @api recordId;
    showRecords = false;
    isLoading = false;
    message;
    countOfRecords;
    label = {
        errorMessage,
        pageSize,
        commLabel : 'Whatsapp Communication',
        iconName : 'standard:whatsapp'
    };
    displayError=false;
    data=[];

    columns = [
        { label: 'Communication Name',  fieldName: 'DOCUMENT_DESCRIPTION' , wrapText: true},
        { label: 'Template Id',         fieldName: 'DOCUMENT_ID' ,  wrapText: true},
        { label: 'Email Id',            fieldName: 'EMAIL_ID' , wrapText: true},
        { label: 'Mobile Number',       fieldName: 'MOBILE_NO' , wrapText: true},
        { label: 'Click PSS Reference', fieldName: 'SNO' , wrapText: true},
        { label: 'Proposal Number',     fieldName: 'APPLICATION_NO' , wrapText: true},
        { label: 'Created On',          fieldName: 'RECORD_PROCESS_DATE' , wrapText: true , type: 'date'},
    ];

    connectedCallback(){
        this.message=this.label.errorMessage;
        this.isLoading = true;
        this.countOfRecords = 0;
        this.getDetails();   
    }

    handleRefresh(){
        this.isLoading=true;
         this.getDetails();
    }

    getDetails(){
        this.data=[];

        getData({recordId: this.recordId})
        .then(result => {
            if(result.StatusCode==200 && result.PolicyInfo.length > 0){
                this.data = result.PolicyInfo;
                this.showRecords=true;
                this.isLoading=false;
                this.countOfRecords = this.data ? this.data?.length : 0;
            }
            else{
                this.message = result.Message;
                this.displayError=true;
                this.isLoading=false;
            }
        })
        .catch(error => {
            console.error('Error in getData>>>', error);
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
        });
    }
}