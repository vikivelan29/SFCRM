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
                        fieldName: 'policyMaturityDate',
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
                        fieldName: 'premiumAmount',
                        label: 'Premium Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'coverName',
                        label: 'Cover Name',
                        type: 'text'
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
                        fieldName: 'policyPlanName',
                        label: 'Policy Plan Name',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyQuoteNumber',
                        label: 'Policy Quote Number',
                        type: 'text'
                    },
                    /* Last Premium Payment Date not present from ABCD, and hence commenting.
                    {
                        fieldName: '',
                        label: 'Last Premium payment date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },*/
                    {
                        fieldName: 'annualPremium',
                        label: 'Annual Premium',
                        type: 'currency'
                    }
                ];
export default class AbcdHealthInsuranceDetails extends LightningElement {
    @api hidetails;
    columns = columns;
}