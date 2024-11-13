import { LightningElement, api, track} from 'lwc'; 
import getPolicyRenewalDetails from '@salesforce/apex/RNWL_IndividualAccRenewalController.getPolicyRenewalDetails';

// list of columns to be displayed for member details
const columns = [
    { label: 'Name', fieldName: 'Name',wrapText: true },
    { label: 'Sum Insured', fieldName: 'SumInsured', cellAttributes: { alignment: 'left' }, wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Upsell Sum Insured', fieldName: 'Upsell_SumInsured', cellAttributes: { alignment: 'left' }, wrapText: true ,type: 'currency', typeAttributes: { currencyCode: 'INR', step: '0.001' } },
    { label: 'Health Return', fieldName: 'healthReturn',wrapText: true },
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

const columns_CombiPolicy = [
    { label: 'Policy Number',       fieldName: 'combi_Policy_Number' , wrapText: true},
    { label: 'Policy Owner',        fieldName: 'combi_Policy_Owner' , wrapText: true},
    { label: 'Policy Start Date',   fieldName: 'combi_Policy_StartDate' , wrapText: true},
    { label: 'Policy End Date',     fieldName: 'combi_Policy_EndDate' , wrapText: true},
    { label: 'Policy Status',       fieldName: 'combi_Policy_Status' , wrapText: true},
    { label: 'Policy Variant',      fieldName: 'combi_Policy_Variant' , wrapText: true},
    { label: 'Product',             fieldName: 'combi_Policy_Product' , wrapText: true},
    { label: 'Sub Plan',            fieldName: 'combi_Policy_SubPlan' , wrapText: true},
    { label: 'Product Type',        fieldName: 'combi_Policy_ProductType' , wrapText: true},

];

const columns_CombiDispositions = [
    { label: 'Disposition Name',  fieldName: 'Disposition_Url' , wrapText: true , type: 'url',
        typeAttributes: {label: { fieldName: 'Disposition_Name' }, target: '_blank'}
    },
    { label: 'Combi Policy Number', fieldName: 'Combi_Policy_Number' , wrapText: true},
    { label: 'Next Call Back Date Time', fieldName: 'Next_CallBack_Datetime' , wrapText: true},
    { label: 'Disposition L1',      fieldName: 'Disostion_L1' , wrapText: true},
    { label: 'Disposition L2',      fieldName: 'Disostion_L2' , wrapText: true},
    { label: 'Disposition L3',      fieldName: 'Disostion_L3' , wrapText: true},
    { label: 'Call Date/Time',      fieldName: 'Call_DateTime' , wrapText: true},
    { label: 'Agent Name',          fieldName: 'Agent_Name' , wrapText: true},
    { label: 'Remarks',             fieldName: 'Remark' , wrapText: true},
    { label: 'Calling Unit',        fieldName: 'Calling_Unit' , wrapText: true},
    { label: 'Calling Mode',        fieldName: 'Calling_Mode' , wrapText: true},
];

export default class RNWL_IndividualAccRenewalDetails extends LightningElement {  
    @api opportunityId;   
    @track policylst;
    @track error;  
    @track ErrorMessage;   
    @track showData; 
    @track showError;  
    isLoading = true; 
    columns = columns;   
    columns_CombiPolicy=columns_CombiPolicy; 
    columns_CombiDispositions=columns_CombiDispositions;
     
    connectedCallback(){ 
        getPolicyRenewalDetails({opportunityId : this.opportunityId})
        .then(result=>{ 
            console.log('result',JSON.stringify(result));
            if(result[0].ErrorCode ==  null){
                this.policylst = result; 
                this.isLoading = false;  
            }else{ 
                this.ErrorMessage = result[0].ErrorMessage;
                this.isLoading = false;  
                this.showError = true;   
            }
        })
        .catch(error=>{
            this.error = error;
            this.ErrorMessage = 'Something went wrong please retry';
            this.showError = true;
            this.isLoading = false;  
            console.log('Raw error Response',JSON.stringify(error));
        });
    }
}