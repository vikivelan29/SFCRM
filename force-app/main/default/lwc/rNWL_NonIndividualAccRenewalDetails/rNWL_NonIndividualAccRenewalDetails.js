import { LightningElement,api, track } from 'lwc';
import getDetails from '@salesforce/apex/RNWL_NonIndAccountRenewalController.getRenewalDetails_NonIndAcc';

export default class RNWL_NonIndividualAccRenewalDetails extends LightningElement {
    @api opportunityId;  // coming from parent component
    @track data=[];
    connectedCallback(){
        getDetails({opportunityId : this.opportunityId})
        .then(result=>{
            if(result){
                this.fetchData(result);
            }
        })
        .catch(error=>{
            console.log('error--'+error);
        });
    }


    fetchData(jsonData){
        let policyDetailSections = {
            sectionLabel : 'Policy Details' , 
            headres : [
                { label: 'Master Policy Number',    fieldName: 'MaterPolicyNumber' , wrapText: true},
                { label: 'Certificate Number',      fieldName: 'Certificate_number' , wrapText: true},
                { label: 'Sum Insured Type',        fieldName: 'Sum_insured_type' , wrapText: true},
                { label: 'Policy Start Date',       fieldName: 'Policy_start_date' , wrapText: true},
                { label: 'Policy Renewal date',     fieldName: 'Policy_renewal_date' , wrapText: true},
                { label: 'Policy Expiry Date',      fieldName: 'Policy_expiry_date' , wrapText: true},
                { label: 'Policy Lapsed Flag',      fieldName: 'Policy_lapsed_flag' , wrapText: true},
                { label: 'Upsell Flag',             fieldName: 'Upsell_Flag' , wrapText: true},
                { label: 'Renewable Flag',          fieldName: 'Renewable_flag' , wrapText: true},
                { label: 'Renewed Flag',            fieldName: 'Renewed_Flag' , wrapText: true},
                { label: 'Combi Flag',              fieldName: 'Combi_Flag' , wrapText: true},
                { label: 'Name of the Proposer',    fieldName: 'Name_of_the_proposer' , wrapText: true},
                { label: 'Name of the product',     fieldName: 'Name_of_product', wrapText: true },
                { label: 'Auto Debit',              fieldName: 'Auto_Debit' , wrapText: true},
            ],
            records : jsonData.policyDetails ,
            sectionAvailable : jsonData.policyDetails.length > 0,
            message : ''
        };

        let premiumDetailSections = {
            sectionLabel : 'Premium Details' , 
            headres : [
                { label: 'Certificate Number',      fieldName: 'Certificate_number' , wrapText: true},
                { label: 'Upsell Net Premium',      fieldName: 'Upsell_Net_Premium' , wrapText: true , type: 'currency'},
                { label: 'Upsell Gross Premium',    fieldName: 'Upsell_Gross_Premium' , wrapText: true , type: 'currency'},
                { label: 'Renewal Net Premium',     fieldName: 'Renewal_Net_Premium' , wrapText: true , type: 'currency'},
                { label: 'Renewal Gross Premium',   fieldName: 'Renewal_Gross_Premium', wrapText: true , type: 'currency'},
            ],
            records : jsonData.premiumDetails,
            sectionAvailable : jsonData.premiumDetails.length > 0,
            message : ''
        };

        let memberDetailSections = {
            sectionLabel : 'Member Details' , 
            headres : [
                { label: 'Certificate Number',  fieldName: 'Certificate_number' , wrapText: true },
                { label: 'Name',                fieldName: 'Name' , wrapText: true},
                { label: 'DOB',                 fieldName: 'DoB' , wrapText: true},
                { label: 'Gender',              fieldName: 'Gender' , wrapText: true},
                { label: 'Email',               fieldName: 'Email' , wrapText: true},
                { label: 'Mobile Number',       fieldName: 'Mobile_Number' , wrapText: true},
                { label: 'Relation',            fieldName: 'Relation' , wrapText: true},
                { label: 'Chronic Disease',     fieldName: 'Chronic_Disease' , wrapText: true},
                { label: 'Disease Disclose',    fieldName: 'Disease_Disclose' , wrapText: true},
                { label: 'Sum Insured',         cellAttributes: { alignment: 'left' }, fieldName: 'SumInsured' , wrapText: true , type: 'currency'},
                { label: 'Net Premium',         cellAttributes: { alignment: 'left' }, fieldName: 'NetPremium' , wrapText: true , type: 'currency'},
                { label: 'New Premium U',       cellAttributes: { alignment: 'left' }, fieldName: 'NetPremium_U' , wrapText: true , type: 'currency'},
                { label: 'CB',                  cellAttributes: { alignment: 'left' }, fieldName: 'CB' , wrapText: true , type: 'currency'},
                { label: 'HR Amount',           cellAttributes: { alignment: 'left' }, fieldName: 'Hr_Amount' , wrapText: true , type: 'currency'},
            ],
            records : jsonData.memberDetails,
            sectionAvailable : jsonData.memberDetails.length > 0,
            message : ''
        };

        let nomineeDetailSections = {
            sectionLabel : 'Nominee Details' , 
            headres : [
                { label: 'Certificate Number',  fieldName: 'Certificate_number' , wrapText: true},
                { label: 'Nominee Name',        fieldName: 'Nominee_Name' , wrapText: true},
                { label: 'Nominee Address',     fieldName: 'Nominee_Address' , wrapText: true},
                { label: 'Nominee Contact No',  fieldName: 'Nominee_Contact_No' , wrapText: true},
            ],
            records : jsonData.nomineeDetails,
            sectionAvailable : jsonData.nomineeDetails.length > 0,
            message : ''
        };

        let renewalInfoSections = {
            sectionLabel : 'Renewal Info' , 
            headres : [
                { label: 'Renewed Master Policy Number',    fieldName: 'Renewed_MaterPolicy_Number' , wrapText: true},
                { label: 'Renewed Certificate Number',      fieldName: 'Renewed_Certificate_Number' , wrapText: true},
                { label: 'Renewed Policy Proposal Number',  fieldName: 'Renewed_Policy_Proposal_Number' , wrapText: true},
                { label: 'Renewed Policy Start Date',       fieldName: 'Renewed_Policy_Start_Date' , wrapText: true},
                { label: 'Renewed Policy Expiry Date',      fieldName: 'Renewed_Policy_Expiry_Date' , wrapText: true},
            ],
            records : jsonData.renewalInfos,
            sectionAvailable : jsonData.renewalInfos.length > 0,
            message : ''
        };

        let combiPolicySection = {
            sectionLabel : 'Combi Policy Details' , 
            headres : [
                { label: 'Policy Number',       fieldName: 'combi_Policy_Number' , wrapText: true},
                { label: 'Policy Owner',        fieldName: 'combi_Policy_Owner' , wrapText: true},
                { label: 'Policy Start Date',   fieldName: 'combi_Policy_StartDate' , wrapText: true},
                { label: 'Policy End Date',     fieldName: 'combi_Policy_EndDate' , wrapText: true},
                { label: 'Policy Status',       fieldName: 'combi_Policy_Status' , wrapText: true},
                { label: 'Policy Variant',      fieldName: 'combi_Policy_Variant' , wrapText: true},
                { label: 'Product',             fieldName: 'combi_Policy_Product' , wrapText: true},
                { label: 'Sub Plan',            fieldName: 'combi_Policy_SubPlan' , wrapText: true},
                { label: 'Product Type',        fieldName: 'combi_Policy_ProductType' , wrapText: true},

            ],
            records : jsonData.combiDetails,
            sectionAvailable : true,
            message : 'No combi-policies to display'
        };

        this.data.push (policyDetailSections, 
                        premiumDetailSections,
                        memberDetailSections, 
                        nomineeDetailSections, 
                        renewalInfoSections,
                        combiPolicySection ); 
        console.log('========>>>',JSON.stringify(this.data));
    }
}