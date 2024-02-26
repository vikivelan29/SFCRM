
window.validateFile = function(inputData) {
    var result = 'Success';
    const columns = inputData.configData.Fields_Name__c.split(',');

        if (!(hasExactProperties(inputData.csvData, columns))) {
            return 'Please make sure the uploaded csv file columns are as per the template';
        } 

        if(inputData.processName === 'ABHFL_Bulk_Create_Case'){
            result = abhflCreateValidation(inputData);

        }else if(inputData.processName === 'ABHFL_Bulk_Close_Case'){
            result = abhflCloseValidation(inputData);

        }else if(inputData.processName === 'ABFL_Bulk_Create_Case'){
            result = abflCreateValidation(inputData);

        }else if(inputData.processName === 'ABFL_Bulk_Close_Case'){
            result = abflCloseValidation(inputData);
        }

    return result;
}

function abhflCreateValidation(inputData){
    let index = 1;
    for (let item of inputData.csvData) {
        if(item["Loan Account No"] === undefined || item["Loan Account No"].trim() === ''){
            return 'Loan Account No is not present/valid on row '+index;
        }
        else if(item["Issue Type Code"] === undefined || item["Issue Type Code"].trim() === '' || item["Issue Type Code"].trim() === 'NA'){
            return 'Issue Type Code is not present/valid on row '+index;
        }
        else if(item["Source"] === undefined || item["Source"].trim() === '' || item["Source"].trim() === 'NA'){
            return 'Source is not present/valid on row '+index;
        }
        else if(item["Sub Source"] === undefined || item["Sub Source"].trim() === ''){
            return 'Sub Source is not present/valid on row '+index;
        }
        else if(item["Description"] === undefined || item["Description"].trim() === ''){
            return 'Description is not present/valid on row '+index;
        }
        else if(item["Block Customer Communication"] === undefined || (item["Block Customer Communication"].trim().toUpperCase() != "TRUE" && item["Block Customer Communication"].trim().toUpperCase() != "FALSE")){
            return 'Invalid Block Customer Communication value provided on row '+index +' - Accepted value - TRUE/FALSE';
        }
        index ++;
    }

    return 'Success';
}

function abhflCloseValidation(inputData){
    let index = 1;
    for (let item of inputData.csvData) {
        if(item["Case number"] === undefined || item["Case number"].trim() === '' || item["Case number"].trim() === 'NA'){
            return 'Case number is not present/valid on row '+index;
        }
        else if(item["Stage"] === undefined || item["Stage"].trim() === '' || (item["Stage"].trim().toUpperCase() != 'RESOLVED' && item["Stage"].trim().toUpperCase() != 'UNRESOLVED')){
            return 'Stage is not present/valid on row '+index +' - Accepted value - Resolved/Unresolved';
        }
        else if(item["Stage"].trim().toUpperCase() === 'RESOLVED' && (item["Resolution Comments"] === undefined || item["Resolution Comments"].trim() === '')){
            return 'Resolution Comments is not present on row '+index;
        }
        else if(item["Stage"].trim().toUpperCase() === 'UNRESOLVED' && (item["Close Unresolved Reason"] === undefined || item["Close Unresolved Reason"].trim() === '')){
            return 'Close Unresolved Reason is not present on row '+index;
        }
        else if(item["Stage"].trim().toUpperCase() === 'UNRESOLVED' && (item["Close Unresolved Details"] === undefined || item["Close Unresolved Details"].trim() === '')){
            return 'Close Unresolved Details is not present on row '+index;
        }
        index ++;
    }
    return 'Success';
}

function abflCreateValidation(inputData){
    let index = 1;
    for (let item of inputData.csvData) {
        if(item["Loan Account No"] === undefined || item["Loan Account No"].trim() === ''){
            return 'Loan Account No is not present/valid on row '+index;
        }
        else if(item["Issue Type Code"] === undefined || item["Issue Type Code"].trim() === '' || item["Issue Type Code"].trim() === 'NA'){
            return 'Issue Type Code is not present/valid on row '+index;
        }
        else if(item["Source"] === undefined || item["Source"].trim() === '' || item["Source"].trim() === 'NA'){
            return 'Source is not present/valid on row '+index;
        }
        else if(item["Description"] === undefined || item["Description"].trim() === ''){
            return 'Description is not present on row '+index;
        }
        else if(item["Block Customer Communication"] === undefined || (item["Block Customer Communication"].trim().toUpperCase() != "TRUE" && item["Block Customer Communication"].trim().toUpperCase() != "FALSE")){
            return 'Invalid Block Customer Communication value provided on row '+index +' - Accepted value - TRUE/FALSE';
        }
        index ++;
    }

    return 'Success';
}

function abflCloseValidation(inputData){
    let index = 1;
    for (let item of inputData.csvData) {
        if(item["Case number"] === undefined || item["Case number"].trim() === '' || item["Case number"].trim() === 'NA'){
            return 'Case number is not present/valid on row '+index;
        }
        else if(item["Resolution Comment"] === undefined || item["Resolution Comment"].trim() === ''){
            return 'Resolution Comment is not present on row '+index;
        }
        index ++;
    }
    return 'Success';
}

// Function to check if each object has the exact same properties as the reference list
function hasExactProperties(objList, propList) {
    for (let obj of objList) {
        const objProperties = Object.keys(obj);
        if (!arraysAreEqual(objProperties, propList)) {
            return false;
        }
    }
    return true;
}

// Function to check if two arrays are equal (have the same elements)
function arraysAreEqual(arr1, arr2) {
    if (arr1.length !== arr2.length) {
        return false;
    }
    for (let i = 0; i < arr1.length; i++) {
        if (arr1[i] !== arr2[i]) {
            return false;
        }
    }
    return true;
}
