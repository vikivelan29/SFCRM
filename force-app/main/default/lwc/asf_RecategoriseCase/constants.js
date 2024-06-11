export const getConstants={
    ACCOUNT_COLUMNS : [{
        label: 'Id',
        fieldName: 'recordId',
        type: 'text',
        fixedWidth: 1,
        hideLabel: true,
        hideDefaultActions: true
    },
    {
        label: 'Customer Name',
        fieldName: 'name',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Email ID',
        fieldName: 'emailId',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Mobile Number',
        fieldName: 'mobile',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Client Code',
        fieldName: 'clientCode',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'PAN Number',
        fieldName: 'pan',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Type',
        fieldName: 'objectType',
        type: 'text',
        initialWidth: 180
    }
    ],
    ASSET_COLUMNS:[{
        label: 'Id',
        fieldName: 'Id',
        type: 'text',
        fixedWidth: 1,
        hideLabel: true,
        hideDefaultActions: true
    },
    {
        label: 'Name',
        fieldName: 'Name',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'LAN Number',
        fieldName: 'LAN__c',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Disbursal Amount',
        fieldName: 'Disbursed_Amount__c',
        type: 'currency',
        initialWidth: 180
    },
    {
        label: 'Loan Disbursement Status',
        fieldName: 'Loan_Disbursement_Status__c',
        type: 'text',
        initialWidth: 180
    },
    {
        label: 'Loan Start Date',
        fieldName: 'Loan_Start_Date__c',
        type: 'date',
        initialWidth: 180
    },
    {
        label: 'Loan End Date',
        fieldName: 'Loan_End_Date__c',
        type: 'date',
        initialWidth: 180
    }
    ],
    RECATEGORISATION_OPTIONS: [
        { label: 'Update Case with Account and Asset', value: 'updAccAsset' },
        { label: 'Proceed to Recategorize Type and Subtype', value: 'recateCTST' },
    ],
    RECATEGORISATION_UPD_ACC : 'Update Case with Account and Asset',
    RECATEGORISATION_PROCEED : 'Proceed to Recategorize Type and Subtype',
    CASE_ELIGIBLE_WITH_NEW_CTST_MSG : 'Current Case Type for this case, is eligible for this Customer and LAN combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?',
    CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and LAN combination. We recommend selecting the right Case Type Sub Type for the case ?',
    INITIAL_OPTIONS:[
        {
            id:1,
            title:'I want to change Account and Asset.'
        },
        {
            id:2,
            title:'I want to change Case Type and Sub-Type.'
        }
    ]

}