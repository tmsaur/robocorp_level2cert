*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.@

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs
Library             Dialogs


*** Variables ***
${ORDERS_URL}               https://robotsparebinindustries.com/orders.csv
${CSV_FILE}                 orders.csv
${GLOBAL_RETRY_AMOUNT}      10x
${GLOBAL_RETRY_INTERVAL}    0.5s
${SECRET_URL}
${URL}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    #Get secret url
    Open the robot order website
    ${orders} =    Get orders file from https
    Log    ${orders}
    FOR    ${ROW}    IN    @{orders}
        Close the modal window
        Log    ${row}
        Fill the form    ${ROW}
        Preview the robot
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Submit the order
        ${pdf} =    Store the receipt and Screenshoot as a PDF file    ${row}[Order number]
        Log    ${pdf}
        ${length} =    Get Length    ${orders}
        Order another robot
    END
    Create ZIP package from PDF files


*** Keywords ***
Get secret url
    ${SECRET_URL} =    Get Secret    secureurl
    ${URL} =    Set Variable    ${SECRET_URL}[url]
    Log    ${URL}

Open the robot order website
    ${SECRET_URL} =    Get Secret    secureurl
    ${url} =    Set Variable    ${SECRET_URL}[url]
    Open Available Browser    ${URL}

Get orders file from https
    ${ORDERS_URL} =    Get Value From User    message
    ${file} =    Download    ${ORDERS_URL}    overwrite=True
    ${table} =    Read table from CSV    orders.csv

    Log    ${file}
    Log    $(table)
    Request Should Be Successful
    Status Should Be    200
    RETURN    ${table}

Close the modal window
    Click Button    css:.btn.btn-dark

Fill the form
    [Arguments]    ${ROW}
    Wait Until Page Contains Element    id:head
    Select From List By Value    head    ${ROW}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    #Submit Form

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    receipt

Store the receipt and Screenshoot as a PDF file
    [Arguments]    ${ROW}
    Wait Until Element Is Visible    receipt
    ${sales_results_html} =    Get Element Attribute    id:receipt    outerHTML

    Set Local Variable    ${robot-receipt}    ${OUTPUT_DIR}${/}order${row}.pdf
    Html To Pdf    content=${sales_results_html}    output_path=${robot-receipt}

    Set Local Variable    ${robot-image}    ${OUTPUT_DIR}${/}image_order${row}.png
    Screenshot    id:robot-preview-image    ${robot-image}
    ${pdf} =    Create PDF from receipt and preview    ${robot-receipt}    ${robot-image}
    RETURN    ${pdf}

Create PDF from receipt and preview
    [Arguments]    ${receipt-filename}    ${image-filename}
    Open PDF    ${receipt-filename}
    @{file-list} =    Create List
    ...    ${receipt-filename}
    ...    ${image-filename}

    Add Files To PDF    ${file-list}    ${receipt-filename}    ${False}
    Close Pdf    ${receipt-filename}

Order another robot
    Click Button    order-another

Create ZIP package from PDF files
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}
    ...    ${zip_file_name}
    ...    include=order*.pdf
    #...    exclude=*.zip,*.xml,*.log
