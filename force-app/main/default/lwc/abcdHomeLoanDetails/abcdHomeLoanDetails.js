import { LightningElement,api } from 'lwc';
const columns = [
                    {
                        fieldName: 'loanAccountNumber',
                        label: 'Loan Account Number',
                        type: 'text'
                    },
                    {
                        fieldName: 'loanStartDate',
                        label: 'Loan Start Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'loanEndDate',
                        label: 'Loan End Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'tenor',
                        label: 'Tenor',
                        type: 'text'
                    },
                    {
                        fieldName: 'disbursementDate',
                        label: 'Loan Disbursement Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'emiAmount',
                        label: 'EMI Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'nextInstallmentDate',
                        label: 'Next Installment Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'loanType',
                        label: 'Loan Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'businessLOB',
                        label: 'Business LOB',
                        type: 'text'
                    },
                    /* Duplicated
                    {
                        fieldName: 'disbursementDate',
                        label: 'Disbursement Date',
                        type: 'text',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }
                    },*/
                    {
                        fieldName: 'sanctionDate',
                        label: 'Sanction Date',
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
                    },
                    {
                        fieldName: 'finalAmount',
                        label: 'Final Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'sanctionAmount',
                        label: 'Sanction Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'rateOfInterest',
                        label: 'Rate of Interest',
                        type: 'text',
                    },
                ];
export default class AbcdHomeLoanDetails extends LightningElement {
    @api hfldetails;
    columns = columns;
}