import { LightningElement, api, track, wire } from 'lwc';
import fetchDetails from '@salesforce/apex/ABHFL_ComplaintInvestigationController.fetchDetails';
import fetchDetailsOnLoad from '@salesforce/apex/ABHFL_ComplaintInvestigationController.fetchDetailsOnLoad';
import generatePDF from '@salesforce/apex/ABHFL_ComplaintInvestigationController.generatePDF';

export default class Abhfl_complaintInvestigation extends LightningElement {

    @api recordId;
    hideBackground = true;
    isLoading = false;
    @track fields = [];
    @track fieldsInColumn1=[];
    @track fieldsInColumn2=[];
    iconName = "utility:ban";
    openSection = false;
    errorResponse='Unable to fetch details. Please try again later.';
    isError = false;

    connectedCallback(){
        this.complaintDetails();
    }

    complaintDetails(){
        this.isLoading = true;
        this.openSection = false;
        this.iconName = "utility:ban";
        this.fieldsInColumn1=[];
        this.fieldsInColumn2=[];
        fetchDetailsOnLoad({caseId:this.recordId})
            .then(result=>{
                if(result){
                    this.fields = [...result];
                    this.fieldsInColumn1 = this.fields.slice(0, Math.ceil(this.fields.length / 2));
                    this.fieldsInColumn2 = this.fields.slice(Math.ceil(this.fields.length / 2));
                    this.iconName = "utility:success";
                    this.isError = false;
                    this.openSection = true;
                }else{
                    this.openSection = false;
                }
            })
            .catch(error=>{
                this.iconName = "utility:error";
                this.isError = true;
                this.openSection = true;
                console.error('Error:'+error.body.message);
            })

        this.isLoading = false;
    }
    
    showDetailsHandler(event){
        fetchDetails({caseId:this.recordId})
            .then(result=>{
                if(result=='success'){
                    console.log('result after update:'+result);
                    this.complaintDetails();
                }
                else{
                    this.isError = true;
                    this.openSection = true;
                    console.error('error error');
                }
            })
            .catch(error=>{
                this.iconName = "utility:error";
                this.isError = true;
                this.openSection = true;
                console.error('Error:'+error.body.message);
            })
    }

    downloadPdfHandler(event){
        generatePDF({pdfHeaderValue:'Complaint Investigation Details',pdfContentValue:this.fields,caseId:this.recordId})
            .then(result=>{
                window.open(result,'_blank');
            })
            .catch(error=>{
                console.error('Error:'+error);
            })
    }

}