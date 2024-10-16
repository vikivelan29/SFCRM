import { LightningElement, api, wire, track} from 'lwc'; 
import getPolicyRenewalDetails from '@salesforce/apex/RNWL_IndividualAccRenewalController.getPolicyRenewalDetails';

const columns = [
    { label: 'Name', fieldName: 'Name',wrapText: true },
    { label: 'Sum Insured', fieldName: 'SumInsured', wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Upsell Sum Insured', fieldName: 'Upsell_SumInsured',wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Health Return', fieldName: 'healthReturn', wrapText: true },
    { label: 'DoB', fieldName: 'DoB', wrapText: true },
    { label: 'Gender', fieldName: 'Gender' ,wrapText: true },
    { label: 'Email', fieldName: 'Email', wrapText: true },
    { label: 'Mobile Number', fieldName: 'Mobile_Number' ,wrapText: true },
    { label: 'Relation', fieldName: 'Relation' ,wrapText: true },
    { label: 'Chronic', fieldName: 'Chronic', wrapText: true  },
    { label: 'CB', fieldName: 'CB', wrapText: true },
    { label: 'Chronic Disease', fieldName: 'Chronic_Disease', wrapText: true },
    { label: 'Disease Disclose', fieldName: 'PED', wrapText: true }
];  

export default class RNWL_IndividualAccRenewalDetails extends LightningElement {  
    @api opportunityId;  // coming from parent component
    @track policylst;
    @track error; 
    columns = columns; 
     
    connectedCallback(){
        getPolicyRenewalDetails({opportunityId : this.opportunityId})
        .then(result=>{
            if(result){
                this.policylst = result; 
                console.log('getPolicyRenewalDetails success ',JSON.stringify(data));
            }
        })
        .catch(error=>{
            this.error = error;
            console.log('Raw error Response',JSON.stringify(error));
        });
    }
    // @wire(getPolicyRenewalDetails, { policyId: "$policyId" })
    //     result({error, data }){
    //     if(data){ 
    //         console.log('Raw error Response',this.policyId);
    //         this.policylst = data; 
    //         console.log('getPolicyRenewalDetails success ',JSON.stringify(data));
    //     }else{
    //         console.log('Raw error Response',this.policyId);
    //         this.error = error;
    //         console.log('Raw error Response',JSON.stringify(error));
    //     }
    // }  
}