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

    connectedCallback(){
        this.complaintDetails();
    }

    complaintDetails(){
        this.isLoading = true;
        this.openSection = false;
        this.iconName = "utility:ban";
        this.fieldsInColumn1=[];
        this.fieldsInColumn2=[];
        console.log('inside top of complaint details aditya');
        fetchDetailsOnLoad({caseId:this.recordId})
            .then(result=>{
                console.log('result:'+JSON.stringify(result));
                if(result){
                    this.fields = [...result];
                    console.log('Result:'+JSON.stringify(result));
                    this.fieldsInColumn1 = this.fields.slice(0, Math.ceil(this.fields.length / 2));
                    this.fieldsInColumn2 = this.fields.slice(Math.ceil(this.fields.length / 2));
                    this.iconName = "utility:success";
                    this.openSection = true;
                }else{
                    this.openSection = false;
                }
            })
            .catch(error=>{
                this.iconName = "utility:error";
                console.error('Error:'+error.body.message);
            })

        this.isLoading = false;
    }

    /*@wire(fetchDetailsOnLoad,{caseId:"$recordId"})
    complaintDetails({data, error}){
        if(data){
            console.log('Data on load:'+JSON.stringify(data));
            if(data.length>0){
                this.fields = [...data];
                console.log('Result:'+JSON.stringify(data));
                this.fieldsInColumn1 = this.fields.slice(0, Math.ceil(this.fields.length / 2));
                this.fieldsInColumn2 = this.fields.slice(Math.ceil(this.fields.length / 2));
                this.iconName = "utility:success";
                this.openSection = true;
            }else{
                this.openSection = false;
            }
        }else if(error){
            this.openSection = false;
            this.iconName = "utility:error";
            console.error('Error:'+error.body.message);
        }
    }*/
    
    showDetailsHandler(event){
        /*this.isLoading = true;
        this.iconName = "utility:expired";
        this.fieldsInColumn1=[];
        this.fieldsInColumn2=[];*/
        fetchDetails({caseId:this.recordId})
            .then(result=>{
                if(result=='success'){
                    console.log('result after update:'+result);
                    this.complaintDetails();
                }
                else{
                    console.error('error error');
                }
                /*this.fields = [...result];
                console.log('Result:'+JSON.stringify(result));
                this.fieldsInColumn1 = this.fields.slice(0, Math.ceil(this.fields.length / 2));
                this.fieldsInColumn2 = this.fields.slice(Math.ceil(this.fields.length / 2));
                this.iconName = "utility:success";*/
            })
            .catch(error=>{
                this.iconName = "utility:error";
                console.error('Error:'+error.body.message);
            })
    }

    downloadPdfHandler(event){
        generatePDF({pdfHeaderValue:'Complaint Investigation Details',pdfContentValue:this.fields,caseId:this.recordId})
            .then(result=>{
                console.log('Result:'+result);
                let pdfPageUrl = '/apex/ABHFL_ComplaintInvestigationPDF'+result;
                console.log('pdfPageUrl::'+pdfPageUrl);
                window.open(pdfPageUrl,'_blank');
            })
            .catch(error=>{
                console.error('Error:'+error.body.message);
            })
    }

}