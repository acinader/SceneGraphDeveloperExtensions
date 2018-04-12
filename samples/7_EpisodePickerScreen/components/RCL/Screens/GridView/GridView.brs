' Copyright (c) 2018 Roku, Inc. All rights reserved.

sub Init()
    m.spinner = m.top.FindNode("spinner")
    m.spinner.uri = "pkg:/components/RCL/loader.png"

    m.Handler_ConfigField = "HandlerConfigGrid"

    m.details = m.top.FindNode("details")
    m.gridNode = invalid
    ' this is to store theme attributes as set theme is called in init o theme should be set after node is created

    ' Observe RCLComponent fields
    m.top.ObserveField("style", "RebuildRowList")
    m.top.ObserveField("posterShape", "RebuildRowList")
    m.top.ObserveField("content", "OnContentSet")

    m.top.ObserveFieldScoped("rowItemFocused", "OnRowItemFocusedChange")
    m.top.ObserveField("focusedChild", "OnFocusedChildChanged")

    ' Set default values
    m.top.style = "standard"
    m.top.posterShape = "16x9"
end sub

sub OnShowSpinnerChange()
    showSpinner = m.top.showSpinner

    if m.gridNode <> invalid
        m.gridNode.visible = not showSpinner
    end if

    m.spinner.visible = showSpinner
    if showSpinner
        m.spinner.control = "start"
    else
        m.spinner.control = "stop"
        OnRowItemFocusedChange()
        rowItemFocused = m.gridNode.rowItemFocused
        valuesToFire = [0, 0]
        if rowItemFocused <> invalid and rowItemFocused.count() > 1
            if rowItemFocused[0] >= 0 then
                valuesToFire[0] = rowItemFocused[0]
            end if
            if rowItemFocused[1] >= 0 then
                valuesToFire[1] = rowItemFocused[1]
            end if
        end if
        m.top.rowItemFocused = valuesToFire
    end if
end sub

sub OnUpdateFocusedItem()
    ?"OnUpdateFocusedItem"
    OnRowItemFocusedChange()
end sub

sub OnFocusedChildChanged()
    if m.gridNode <> invalid and m.top.IsInFocusChain() and not m.gridNode.HasFocus()
        m.gridNode.SetFocus(true)
    end if
end sub

sub RebuildRowList()
    configuration = GetConfigurationForStyle(m.top.style)
    if configuration <> invalid
        CreateNewOrUpdateGridNode(configuration.node, configuration.fields)
        if m.gridNode <> invalid
            CreateNewOrUpdateGridNode("", GetConfigurationForPosterShape(m.top.posterShape, m.gridNode.rowHeights))
        end if
    end if
end sub

sub CreateNewOrUpdateGridNode(componentName = "" as String, fields = {} as Object)
    observers = {
        "rowItemFocused": "SimulateAlias"
        "rowItemSelected": "SimulateAlias"
        "numRows": "SimulateAlias"
        "jumpToRowItem": "SimulateAlias"
    }

    if componentName.Len() > 0 and m.gridNode <> invalid and m.gridNode.Subtype() <> componentName
        ' remove precious node and observers
        m.top.RemoveChild(m.gridNode)
        for each field in observers
            m.gridNode.UnobserveFieldScoped(field)
        end for
        m.gridNode = invalid
    end if

    ' If node don't created or removed then create new grid node
    if m.gridNode = invalid
        m.gridNode = m.top.CreateChild(componentName)
        m.gridNode.AddField("itemTextColorLine1", "color", true)
        m.gridNode.AddField("itemTextColorLine2", "color", true)

        if m.LastThemeAttributes <> invalid then
            RCL_SetTheme(m.LastThemeAttributes)
        end if
        if m.top.IsInFocusChain() then m.gridNode.SetFocus(true)

        if m.gridNode <> invalid
            for each field in observers
                m.gridNode.ObserveFieldScoped(field, observers[field])
            end for
            if m.top.content <> invalid then m.gridNode.content = m.top.content
        end if
    end if

    if m.gridNode <> invalid and fields <> invalid
        m.gridNode.SetFields(fields)
    end if
end sub

sub OnContentSet()
    if m.gridNode <> invalid
        isNewContent = m.gridNode.content = invalid or m.top.content = invalid or not m.gridNode.content.IsSameNode(m.top.content)
        if isNewContent then
            SetAliasData("content", m.top.content)
            if m.gridNode.rowItemFocused = invalid or m.gridNode.rowItemFocused.Count() = 0
                m.gridNode.rowItemFocused = [0, 0]
            end if
            OnRowItemFocusedChange()
        end if
    end if
end sub

sub OnRowItemFocusedChange()
    if m.gridNode <> invalid
        content = m.top.content
        itemContent = invalid
        focusedItem = m.gridNode.rowItemFocused
        if content <> invalid and Type(focusedItem) = "roArray" and focusedItem.Count() = 2
            rowIndex = focusedItem[0]
            if rowIndex < 0 then rowIndex = 0
            row = content.GetChild(rowIndex)
            if row <> invalid
                itemIndex = focusedItem[1]
                if itemIndex < 0 then itemIndex = 0
                itemContent = row.GetChild(itemIndex)
            end if
        end if
        m.details.content = itemContent
    end if
end sub

sub SimulateAlias(event as Object)
    if m.gridNode <> invalid
        field = event.GetField()
        data = event.GetData()
        SetAliasData(field, data)
    end if
end sub

sub SetAliasData(field as String, data as Object)
    m.top[field] = data
    if m.gridNode <> invalid
        m.gridNode[field] = data
    end if
end sub

function GetConfigurationForStyle(style as String) as Object
    ' Base row list configuration fields
    rowListTranslation = [0, 265]
    rowListRowWidth = 1280
    rowListRowHeight = GetDefaultRowHeight()
    rowListHeroRowHeight = 340
    defaultItemSpacing = [20, 20]
    xLabelAndFocusOffset = 125
    yLabelOffset = 14
    numRows = 2
    showRowCounter = true
    showRowLabel = true

    ' Custom UI components
    rowFocusAnimationStyle = "fixedFocusWrap"
    itemComponentName = "StandardGridItemComponent"
    rowTitleComponentName = "DefaultRowTitleComponent"

    styles = {
        "standard": {
            node: "RowList"
            fields: {
                rowFocusAnimationStyle: rowFocusAnimationStyle
                itemComponentName: itemComponentName
                rowTitleComponentName: rowTitleComponentName
                itemSpacing: defaultItemSpacing
                rowItemSpacing: [defaultItemSpacing]

                itemSize: [rowListRowWidth, rowListRowHeight]
                rowHeights: [rowListRowHeight]
                translation: rowListTranslation
                rowLabelOffset: [xLabelAndFocusOffset, yLabelOffset]
                focusXOffset: [xLabelAndFocusOffset]

                numRows: numRows
                showRowCounter: showRowCounter
                showRowLabel: showRowLabel
            }
        }
        "hero": {
            node: "RowList"
            fields: {
                rowFocusAnimationStyle: rowFocusAnimationStyle
                itemComponentName: itemComponentName
                rowTitleComponentName: rowTitleComponentName
                itemSpacing: defaultItemSpacing
                rowItemSpacing: [defaultItemSpacing]

                itemSize: [rowListRowWidth, rowListRowHeight]
                rowHeights: [rowListHeroRowHeight, rowListRowHeight]
                translation: rowListTranslation
                rowLabelOffset: [xLabelAndFocusOffset, yLabelOffset]
                focusXOffset: [xLabelAndFocusOffset]

                numRows: numRows
                showRowCounter: showRowCounter
                showRowLabel: showRowLabel
            }
        }
    }

    if styles[style] = invalid then style = "standard"

    return styles[style]
end function

function GetDefaultRowHeight() as Float
    defaultItemHeight = 150
    topMargin = 45 ' label height + spacing
    if m.top.posterShape = "portrait" then
        defaultRowHeight = defaultItemHeight * 1.5
    end if

    return defaultItemHeight + topMargin
end function

function GetRowItemSizeForPosterShape(style as String, rowHeight as Integer) as Object
    topMargin = 45 ' label height + spacing
    height = rowHeight - topMargin
    styles = {
        "portrait": [Int(height * 3 / 4), height]
        "4x3": [Int(height * 4 / 3), height]
        "16x9": [Int(height * 16 / 9), height]
        "square": [height, height]
    }
    if styles[style] = invalid then style = "16x9"

    return styles[style]
end function

function GetConfigurationForPosterShape(style as String, rowHeights as Object) as Object
    if Type(rowHeights) <> "roArray" or rowHeights.Count() = 0 then return invalid
    rowItemSize = []

    for each height in rowHeights
        rowItemSize.Push(GetRowItemSizeForPosterShape(style, height))
    end for

    return { rowItemSize: rowItemSize }
end function

sub RCL_SetTheme(theme as Object)
    colorTheme = {
        TextColor: {
            gridNode: [
                "rowLabelColor"
                "itemTextColorLine1"
                "itemTextColorLine2"
            ]
            details: [
                "titleColor"
                "descriptionColor"
            ]
        }
        focusRingColor : {
            gridNode: ["focusBitmapBlendColor"]
        }
    }

    RCL_setThemeFieldstoNode(m, colorTheme, theme)


    gridThemeAttributes = {
        rowLabelColor:       { gridNode: "rowLabelColor" }
        focusRingColor:      { gridNode: "focusBitmapBlendColor" }
        focusFootprintColor: { gridNode: "focusFootprintBlendColor" }
        itemTextColorLine1:  { gridNode: "itemTextColorLine1" }
        itemTextColorLine2:  { gridNode: "itemTextColorLine2" }

        ' details attributes
        descriptionmaxWidth: { details: "maxWidth" }
        titleColor:          { details: "titleColor" }
        descriptionColor:    { details: "descriptionColor" }
        descriptionMaxLines: { details: "descriptionMaxLines" }
    }
    RCL_setThemeFieldstoNode(m, gridThemeAttributes, theme)
end sub

function RCL_GetViewType() as String
    return "gridView"
end function