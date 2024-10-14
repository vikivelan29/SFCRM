import { LightningElement, api, track} from 'lwc'; 
import getPolicyRenewalDetails from '@salesforce/apex/RNWL_IndividualAccRenewalController.getPolicyRenewalDetails';

// list of columns to be displayed for member details
const columns = [
    { label: 'Name', fieldName: 'Name',wrapText: true },
    { label: 'Sum Insured', fieldName: 'SumInsured', wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Upsell Sum Insured', fieldName: 'Upsell_SumInsured',wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Health Return', fieldName: 'healthReturn',wrapText: true },
    { label: 'DoB', fieldName: 'DoB', wrapText: true },
    { label: 'Gender', fieldName: 'Gender' ,wrapText: true },
    { label: 'Email', fieldName: 'Email', wrapText: true },
    { label: 'Mobile Number', fieldName: 'Mobile_Number' ,wrapText: true },
    { label: 'Relation', fieldName: 'Relation' ,wrapText: true },
    { label: 'Chronic', fieldName: 'Chronic', wrapText: true  },
    { label: 'CB', fieldName: 'CB', wrapText: true }
];  

export default class RNWL_IndividualAccRenewalDetails extends LightningElement {  
    @api opportunityId;  // coming from parent component
    @track policylst;
    @track error;  
    @track ErrorMessage;   
    @track showData; 
    @track showError;  
    columns = columns;    
     
    connectedCallback(){
        console.log('this.opportunityId',this.opportunityId);
        getPolicyRenewalDetails({opportunityId : this.opportunityId})
        .then(result=>{
            console.log('getPolicyRenewalDetails success ',JSON.stringify(result));
            if(result[0].ErrorCode ==  null){
                this.policylst = result; 
                this.showData = true;
                console.log('getPolicyRenewalDetails success ',JSON.stringify(result));
            }else{
                this.ErrorMessage = result[0].ErrorMessage;
                this.showError = true;             
            }
        })
        .catch(error=>{
            this.error = error;
            this.ErrorMessage = 'Something went wrong please retry';
            this.showError = true;
            console.log('Raw error Response',JSON.stringify(error));
        });
    }
}