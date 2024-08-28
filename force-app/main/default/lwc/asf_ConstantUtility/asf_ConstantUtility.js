export const lanLabels = {
    DEFAULT: {
        SELECT_PRODUCT: "Select Product",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /Product# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and Product combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and Product combination. We recommend selecting the right Case Type Sub Type for the case ?',
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
    CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/Product Tagging",
    CTST_COLS: [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'LOB', fieldName: 'LOB__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ],
    RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same Product as current case",
    CREATE_SR_WITH_FA: "Create Case with Product",
    FA_VALIDATION_MESSAGE: "Please select Product Number to process Case type search",
    FA_MANDATORY_PREFRAMEWORK: "Please tag LAN to customer to process Case Type Search",
    CREATE_CASE_WITH_FA: "Create Case with Product",
    AUTO_COMM_BU_LIST: ['ABFL','ABHFL','ABWM','Payments']
    },
    ABHFL: {
        SELECT_PRODUCT: "Select LAN",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /LAN# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and LAN combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and LAN combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/LAN Tagging",
        CTST_COLS: [
            { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
        ],
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same LAN as current case",
        CREATE_SR_WITH_FA: "Create Case with LAN",
        FA_VALIDATION_MESSAGE: "Please select Loan Account Number to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag LAN to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with LAN"
    
    },
    ABFL: {
        SELECT_PRODUCT: "Select LAN",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /LAN# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and LAN combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and LAN combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/LAN Tagging",
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same LAN as current case",
        CREATE_SR_WITH_FA: "Create Case with LAN",
        FA_VALIDATION_MESSAGE: "Please select Loan Account Number to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag LAN to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with LAN"
    },
    ABSLI: {
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
            label: 'Policy No',
            fieldName: 'Policy_No__c',
            type: 'text',
            initialWidth: 180
        },
        {
            label: 'Policy Status',
            fieldName: 'Status',
            type: 'text',
            initialWidth: 180
        },
        {
            label: 'Policy Type',
            fieldName: 'Type__c',
            type: 'text',
            initialWidth: 180
        },
        {
            label: 'Application No.',
            fieldName: 'Application_Number__c',
            type: 'text',
            initialWidth: 180
        }
        ],
        CTST_COLS: [
            { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
        ],
        SELECT_PRODUCT: "Select Policy",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /Policy# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and Policy combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and Policy combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/Policy Tagging",
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same Policy as current case",
        CREATE_SR_WITH_FA: "Create Case with Policy",
        FA_VALIDATION_MESSAGE: "Please select Policy to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag Policy to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with Policy"
    },
    ABSLIG: {
        ASSET_COLUMNS : [{
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
            fixedWidth: 1,
            hideLabel: true,
            hideDefaultActions: true
        },
        {
            label: 'Policy No',
            fieldName: 'Policy_No__c',
            type: 'text',
            initialWidth: 220
        },
        {
            label: 'Zone',
            fieldName: 'Zone__c',
            type: 'text',
            initialWidth: 220
        },
        {
            label: 'SM Name',
            fieldName: 'SM_Name__c',
            type: 'text',
            initialWidth: 220
        },
        {
            label: 'Policy Type',
            fieldName: 'Type__c',
            type: 'text',
            initialWidth: 220
        }
        ],
        CTST_COLS: [
            { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
            { label: 'Type', fieldName: 'Type__c', type: 'text' },
            { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
        ],
        SELECT_PRODUCT: "Select Policy",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /Policy# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and Policy combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and Policy combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/Policy Tagging",
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same Policy as current case",
        CREATE_SR_WITH_FA: "Create Case with Policy",
        FA_VALIDATION_MESSAGE: "Please select Policy to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag Policy to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with Policy"
    },
    Payments: {
        SELECT_PRODUCT: "Select LAN",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /LAN# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and LAN combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and LAN combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/LAN Tagging",
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same LAN as current case",
        CREATE_SR_WITH_FA: "Create Case with LAN",
        FA_VALIDATION_MESSAGE: "Please select Loan Account Number to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag LAN to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with LAN"
    },
    ABWM: {
        SELECT_PRODUCT: "Select LAN",
        PRODUCT_SEARCH_PLACEHOLDER: "Enter Customer Name /Client Code /Email /Mobile /LAN# /PAN#",
        CASE_ELIGIBLE_WITH_NEW_CTST_MSG: "Current Case Type for this case, is eligible for this Customer and LAN combination. Do you want to proceed with existing Case Type Sub Type or Re-Categorize Type Subtype?",
        CASE_NOT_ELIGIBLE_WITH_EXISING_CST_MSG : 'Current Case Type for this case, is not eligible for this Customer and LAN combination. We recommend selecting the right Case Type Sub Type for the case ?',
        CUSTOMER_TAGGING_CARD_TITLE: "Customer/Prospect/LAN Tagging",
        RELATE_DUP_LAN_ERRORMSG: "Parent case should belong to same LAN as current case",
        CREATE_SR_WITH_FA: "Create Case with LAN",
        FA_VALIDATION_MESSAGE: "Please select Loan Account Number to process Case type search",
        FA_MANDATORY_PREFRAMEWORK: "Please tag LAN to customer to process Case Type Search",
        CREATE_CASE_WITH_FA: "Create Case with LAN"
    }
  };