import { LightningElement,api } from 'lwc';
const columns = [
                    {
                        fieldName: 'applicationNumber',
                        label: 'Application Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyNumber',
                        label: 'Policy Number',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyStatus',
                        label: 'Policy Status',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyTerm',
                        label: 'Policy Term',
                        type: 'text'
                    },
                    {
                        fieldName: 'maturityDate',
                        label: 'Policy Maturity Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'issueDate',
                        label: 'Policy Issuance Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'policyPremium',
                        label: 'Premium Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'sumAssured',
                        label: 'Insured Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'premiumMode',
                        label: 'Premium Mode',
                        type: 'text'
                    },
                    {
                        fieldName: 'policyType',
                        label: 'Policy Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'planName',
                        label: 'Policy Plan Name',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyQuoteNumber',
                        label: 'Policy Quote Number',
                        type: 'text'
                    },
                    {
                        fieldName: '',
                        label: 'Last Premium payment date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    /* Annual Premius already present as policy premium and hence not required here.
                    {
                        fieldName: '',
                        label: 'Annual Premium',
                        type: 'currency'
                    }*/
                ];
export default class AbcdLifeInsuranceDetails extends LightningElement {
    @api lidetails;
    columns = columns;
}