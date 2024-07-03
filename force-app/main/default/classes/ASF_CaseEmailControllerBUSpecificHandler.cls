/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 02-09-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   02-09-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.NcssMethodCount')
public class ASF_CaseEmailControllerBUSpecificHandler {
    /**
     * @description - Replace the dynamic fields
     * @param inputText - Hold the input test
     * @param resultMap - map with fields and values
     * @param isABHFL - holds true if the value is ABFHL
     * @return inputText with the values
     */
    public static String replaceDynamicFields(String inputText, Map<String, String> resultMap, Boolean isABHFL) {
        if(isABHFL){
            String regExpForMultipleChildsValue = '\\@\\@(.*?)\\@\\@';

            Pattern regex = Pattern.compile(regExpForMultipleChildsValue);
            Matcher matcher = regex.matcher(inputText);

            while (matcher.find()) {
                String capturedString = matcher.group(1);
                String concatinatedSubFields = '';
                for(String str : resultMap.keySet()){
                    if(capturedString.contains('##' + str + '##')){
                        concatinatedSubFields+=str + ',';
                    }
                }
                String subFeildsValue = generateMultipleFields(capturedString, concatinatedSubFields, resultMap);
                inputText = inputText.replace('@@' + capturedString + '@@', subFeildsValue);
            }    

            if (resultMap != null){
                for (String s : resultMap.keySet()) {
                    inputText = inputText.replace('##' + s + '##', resultMap.get(s));
                }
            }
        }
        
        return inputText;
    }

    private static String generateMultipleFields(String capturedString, String concatinatedSubFields, Map<String, String> resultMap) {
        List<String> subFields = concatinatedSubFields.split('\\,');
        List<List<String>> listMPL = new List<List<String>>();
        String resultantString = '';
        for(String str : subFields){
            if(String.isNotEmpty(resultMap.get(str))){
                listMPL.add(resultMap.get(str).split('\\,'));
            }
        }

        Integer maxFieldNum = (listMPL.isEmpty())?0:listMPL[0].size();
        for(Integer i=0; i<maxFieldNum; i++){
            String storeSingleRow = capturedString;
            for(Integer j =0;j<subFields.size();j++){
                storeSingleRow = storeSingleRow.replace('##' + subFields[j] + '##', listMPL[j][i])+' \n';
            }
            resultantString+=storeSingleRow;
        }
        return resultantString;
    }

    private static string createSubQuery(String relationshipNameOfObject, List<String> fields){
        return '(Select Id, ' + String.join(fields,',') + ' From ' + relationshipNameOfObject +')';
    }

    /**
     * @description handles the subquesires of the current object
     * @param subQueriesToReplace
     * @return Map<String, String> - holds the subqueries fields with values
     */
    public static Map<String, String> handleSubQueries(Set<String> subQueriesToReplace) {
           // code for create and add subqueries into fieldsToQueryUniqueset...    
           Map<String, List<String>> subQueryMap = new Map<String, List<String>>();
           Map<String, String> subFieldWithQuery = new Map<String, String>();

           for(String subField : subQueriesToReplace){
               subFieldWithQuery.put(subField, '');
               List<String> objectAndField = subField.split('\\.'); 
               if(!subQueryMap.containsKey(objectAndField[0])){
                   subQueryMap.put(objectAndField[0], new List<String>());
               }
               subQueryMap.get(objectAndField[0]).add(objectAndField[1]);
           }

           for(String str : subQueryMap.keySet()){
               String subQuery =  createSubQuery(str, subQueryMap.get(str));
               for(String fullSubField : subFieldWithQuery.keySet()){
                   List<String> objectAndField = fullSubField.split('\\.');
                   if(str == objectAndField[0]){
                       subFieldWithQuery.put(fullSubField, subQuery);
                   }
               }
           }
           return subFieldWithQuery;
    }
}