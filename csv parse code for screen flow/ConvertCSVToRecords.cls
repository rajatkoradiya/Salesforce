public without sharing class ConvertCSVToRecords {
    @InvocableMethod(label='Convert CSV File to Records from ContentDocumentId')
    public static list<Response> convertAndInsertPayments(list<Request> inputs) {
        list<Response> responseList = new List<Response>();

        for (Request curInput : inputs) {
            Response output = new Response();
            //output.convertedCSVRows = new List<SObject>{};
            if (curInput.contentDocumentId == null) {
                throw new FlowCustomException(
                    'You need to provide ContentDocument Id as inputs to this Flow action.'
                );
            } else {
                SObjectType sObjType = ((SObject) Type.forName('blng__Payment__c').newInstance())
                    .getSObjectType();
                Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

                List<SObject> curFileConvertedCSVRows = new List<SObject>();

                String curContentDocumentId = curInput.contentDocumentId;

                //convert the csv to blob
                Blob csvBlobContent = getCsvContent(curContentDocumentId);

                //convert blob value to string
                String csvStringContent = blobToString(csvBlobContent, 'UTF-8');
                System.debug(logginglevel.ERROR, '*** csvStringContent : ' + csvStringContent);

                csvStringContent = csvStringContent.replaceAll('(\r\n|\r)', '\n');
                String[] csvRows = csvStringContent.split('\n');

                System.debug(logginglevel.ERROR, '*** csvRows : ' + csvRows);
                System.debug(logginglevel.ERROR, '*** first csvRows : ' + csvRows[0]);

                //get the bank statement mapping
                if (curInput.bankAccountId == null) {
                    //throw an exception for not having bank account
                    throw new FlowCustomException(
                        'You need to provide bankAccountId as inputs to this Flow action.'
                    );
                }

                //get bank statement mapping
                list<BankStatementMapping__c> bankStatementMappings = getBankStatementMappings(
                    curInput.bankAccountId
                );

                if (bankStatementMappings.isEmpty()) {
                    throw new FlowCustomException(
                        'There are not Bank Statement mapping exist with the current bank account. Please contact your administrator to create some bank statement mappings.'
                    );
                }

                //generate bank statement
                BankStatement__c bankStatementRecord = new BankStatement__c();
                bankStatementRecord.BankStatementIdExternal__c = curInput.fileName.replace(
                    '.csv',
                    ''
                );
                bankStatementRecord.Status__c = 'Open';
                bankStatementRecord.BankAccount__c = curInput.bankAccountId;
                try {
                    insert bankStatementRecord;
                } catch (Exception ex) {
                    throw new FlowCustomException(ex.getMessage());
                }

                Map<String, BankStatementMapping__c> columnHeaderToStatementMapping = new Map<String, BankStatementMapping__c>();
                String firstColumnHeaderString = '';

                for (BankStatementMapping__c bankStatementMapping : bankStatementMappings) {
                    columnHeaderToStatementMapping.put(
                        bankStatementMapping.ColumnHeaderValue__c,
                        bankStatementMapping
                    );

                    if (bankStatementMapping.FirstHeaderCell__c) {
                        firstColumnHeaderString = bankStatementMapping.ColumnHeaderValue__c;
                    }
                }

                System.debug(
                    logginglevel.ERROR,
                    '*** columnHeaderToStatementMapping : ' + columnHeaderToStatementMapping
                );

                System.debug(
                    logginglevel.ERROR,
                    '*** firstColumnHeaderString : ' + firstColumnHeaderString
                );

                Map<Integer, String> sequenceNumToColumnHeader = new Map<Integer, String>();

                //clone csv rows to find the header column
                list<String> csvRowsCloned = new List<String>();
                csvRowsCloned.addAll(csvRows);

                System.debug(logginglevel.ERROR, '*** csvRowsCloned : ' + csvRowsCloned);

                //Integer rowCount = 0;
                for (String currentCSVRow : csvRowsCloned) {
                    System.debug(logginglevel.ERROR, '*** currentCSVRow : ' + currentCSVRow);
                    //check if the current row is the row from to start to create the records
                    if (!currentCSVRow.contains(firstColumnHeaderString)) {
                        csvRows.remove(0);
                        //rowCount++;
                        continue;
                    }

                    String[] currentCSVRowData = currentCSVRow.split(',');

                    Integer sequenceNumber = 0;
                    for (String currentCSVRowCell : currentCSVRowData) {
                        sequenceNumToColumnHeader.put(sequenceNumber, currentCSVRowCell);
                        sequenceNumber++;
                    }

                    break;
                }

                System.debug(
                    logginglevel.ERROR,
                    '*** sequenceNumToColumnHeader : ' + sequenceNumToColumnHeader
                );

                System.debug(logginglevel.ERROR, '*** csvRows AFTER 1 : ' + csvRows);

                String row1 = handleUnescapedDelimieter(csvRows[1]);

                list<String> columnValues = row1.split(',');

                System.debug(logginglevel.ERROR, '*** columnValues : ' + columnValues);

                System.debug(logginglevel.ERROR, '*** columnValues : ' + columnValues.size());

                System.debug(
                    logginglevel.ERROR,
                    '*** columnValues[value] : ' +
                    columnValues[0].replaceAll(':quotes:', '').replaceAll(':comma:', ',')
                );

                csvRows.remove(0);

                if (csvRows.isEmpty()) {
                    return null;
                }

                //loop through all the rows
                BankStatementLine__c[] bankStatementLines = new List<BankStatementLine__c>();
                for (String currentRow : csvRows) {
                    String currentRowEscapedData = handleUnescapedDelimieter(currentRow);

                    list<String> currentRowValues = currentRowEscapedData.split(',');

                    if (currentRowValues.isEmpty()) {
                        continue;
                    }

                    Boolean addPayments = true;

                    BankStatementLine__c bankStatementLine = new BankStatementLine__c();
                    //loop through all the cell in single row
                    for (Integer i = 0; i < currentRowValues.size(); i++) {
                        if (currentRowValues[i] == null) {
                            continue;
                        }
                        if (!sequenceNumToColumnHeader.containsKey(i)) {
                            continue;
                        }
                        String headerValue = sequenceNumToColumnHeader.get(i);

                        if (
                            String.isBlank(headerValue) ||
                            !columnHeaderToStatementMapping.containsKey(headerValue)
                        ) {
                            continue;
                        }

                        System.debug(logginglevel.ERROR, '*** headerValue : ' + headerValue);

                        BankStatementMapping__c bankStmtMappingRecord = columnHeaderToStatementMapping.get(
                            headerValue
                        );

                        String cellValue = currentRowValues[i]
                            .replaceAll(':quotes:', '')
                            .replaceAll(':comma:', ',')
                            .trim();

                        System.debug(logginglevel.ERROR, '*** cellValue : ' + cellValue);

                        System.debug(
                            logginglevel.ERROR,
                            '*** cellValue : ' + cellValue.contains('INV-')
                        );

                        //check for valid values
                        if (
                            String.isNotBlank(
                                bankStmtMappingRecord.AllowedValuesCommaSeparated__c
                            ) &&
                            !bankStmtMappingRecord.AllowedValuesCommaSeparated__c.contains(
                                cellValue
                            )
                        ) {
                            addPayments = false;
                            break;
                        }

                        if (
                            String.isNotBlank(bankStmtMappingRecord.FieldType__c) &&
                            bankStmtMappingRecord.FieldType__c.equalsIgnoreCase('Date')
                        ) {
                            Date formatedCellDate = date.parse(cellValue);
                            bankStatementLine.put(
                                bankStmtMappingRecord.FieldAPIName__c,
                                formatedCellDate
                            );
                        } else if (
                            String.isNotBlank(bankStmtMappingRecord.FieldType__c) &&
                            (bankStmtMappingRecord.FieldType__c.equalsIgnoreCase('Number') ||
                            bankStmtMappingRecord.FieldType__c.equalsIgnoreCase('Currency'))
                        ) {
                            cellValue = cellValue.replaceAll(',', '');
                            Decimal formatedNumberValue = Decimal.valueOf(cellValue);
                            bankStatementLine.put(
                                bankStmtMappingRecord.FieldAPIName__c,
                                formatedNumberValue
                            );
                        } else {
                            bankStatementLine.put(bankStmtMappingRecord.FieldAPIName__c, cellValue);
                        }
                    }

                    if (bankStatementLines != null & addPayments) {
                        bankStatementLines.add(bankStatementLine);
                    }

                    System.debug(
                        logginglevel.ERROR,
                        '*** bankStatementLines : ' + bankStatementLines
                    );
                }

                if (bankStatementLines.size() > 0) {
                    for (BankStatementLine__c bankStatementLine : bankStatementLines) {
                        bankStatementLine.put('Status__c', (String) 'Unallocated');
                        bankStatementLine.put('BankStatement__c', (Id) bankStatementRecord.Id);
                    }

                    System.debug(
                        logginglevel.ERROR,
                        '*** bankStatementLines : ' + bankStatementLines
                    );

                    try {
                        insert bankStatementLines;
                    } catch (Exception ex) {
                        throw new FlowCustomException(ex.getMessage());
                    }
                }

                output.isSuccess = true;
                responseList.add(output);
            }
        }

        return responseList;
    }

    private static Blob getCsvContent(String contentDocumentId) {
        ContentVersion csvFile = [
            SELECT VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId AND IsLatest = TRUE
        ];
        System.debug('contentDocumentId is: ' + contentDocumentId);
        System.debug('csvFile is: ' + csvFile);
        return csvFile.VersionData;
    }

    /* Converting the CSV file input(BLOB format) to a string */
    private static String blobToString(Blob input, String inCharset) {
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new List<String>(bytesCount);
        for (Integer i = 0; i < bytesCount; ++i)
            bytes[i] = hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }

    private static list<BankStatementMapping__c> getBankStatementMappings(Id bankAccountId) {
        return [
            SELECT
                id,
                BankAccount__c,
                ColumnHeaderValue__c,
                FieldAPIName__c,
                FirstHeaderCell__c,
                FieldType__c,
                DateFormat__c,
                ReferenceExist__c,
                ExternalId__c,
                AllowedValuesCommaSeparated__c
            FROM BankStatementMapping__c
            WHERE BankAccount__c = :bankAccountId
        ];
    }

    private static String handleUnescapedDelimieter(String csvLine) {
        String prevLine = csvLine;

        Integer startIndex;

        Integer endIndex;

        while (csvLine.indexOf('"') > -1) {
            if (startIndex == null) {
                startIndex = csvLine.indexOf('"');

                csvLine =
                    csvLine.substring(0, startIndex) +
                    ':quotes:' +
                    csvLine.substring(startIndex + 1, csvLine.length());
            } else {
                if (endIndex == null) {
                    endIndex = csvLine.indexOf('"');

                    csvLine =
                        csvLine.substring(0, endIndex) +
                        ':quotes:' +
                        csvLine.substring(endIndex + 1, csvLine.length());
                }
            }

            if (startIndex != null && endIndex != null) {
                String sub = csvLine.substring(startIndex, endIndex);

                sub = sub.replaceAll(',', ':comma:');

                csvLine =
                    csvLine.substring(0, startIndex) +
                    sub +
                    csvLine.substring(endIndex, csvLine.length());

                startIndex = null;

                endIndex = null;
            }
        }

        System.debug('prevLine:::' + prevLine);

        System.debug('csvLine:::' + csvLine);

        return csvLine;
    }

    public class Request {
        @InvocableVariable(label='CSV file Id' required=true)
        public string contentDocumentId;

        @InvocableVariable(label='Bank Account Id' required=true)
        public string bankAccountId;

        @InvocableVariable(label='File Name' required=true)
        public string fileName;
    }

    public class Response {
        @InvocableVariable(label='Success?')
        public Boolean isSuccess;
    }

    public class FlowCustomException extends Exception {
    }
}
