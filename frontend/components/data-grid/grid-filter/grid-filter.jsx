'use strict';

const PropTypes = require('prop-types');
const DocContext = require('./../../../doc-context.js');
const prepareData = require('./../../../../libs/prepaireFilterData');

const React = require('react'),
    styles = require('./grid-filter-styles');

class GridFilter extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            gridConfig: props.gridConfig, // grid config
            data: props.data
        };

        this.handleChange = this.handleChange.bind(this);
        this.prepareFilterFields = this.prepareFilterFields.bind(this);
        this.returnInterval = this.returnInterval.bind(this);
    }

    /**
     * Обработчик на изменения инпутов
     */
    handleChange(e) {
        this.saveFilterContent(e.target.name, e.target.value);
        /*
                let data = this.props.data;
                let row = data.find(item => item.name === e.target.name);

                // проверим на наличие полей для фильтрации
                if (!data.length || !row) {
                    data = prepareData(this.props.gridConfig, this.props.docTypeId);
                } else {
                    data = this.props.data;
                }

                let value = e.target.value,
                    id = e.target.name,
                    index,
                    isIntervalStart = !!id.match(/_start/),
                    isIntervalEnd = !!id.match(/_end/);
                let fieldName = id;

                // надо найти элемент массива с данными для этого компонента
                for (let i = 0; i < data.length; i++) {

                    isIntervalStart = !!id.match(/_start/);
                    isIntervalEnd = !!id.match(/_end/);

                    if (isIntervalStart) {
                        // will replace start from firldName
                        fieldName = id.replace(/_start/i, '');
                    }

                    if (isIntervalEnd) {
                        // will replace end from firldName
                        fieldName = id.replace(/_end/i, '');
                    }

                    if (data[i].name === (fieldName)) {
                        index = i;
                        break;
                    }
                }

                if (index > -1) {
                    if (isIntervalStart) {
                        data[index].start = value;
                    }
                    if (isIntervalEnd) {
                        data[index].end = value;
                    }

                    data[index].value = value;
                }

                // сохраним фильтр
                DocContext.filter[this.props.docTypeId] = data;

                if (this.props.handler) {
                    this.props.handler(data);
                }
        */

        this.forceUpdate();
    }

    /**
     * сохранит значение фильтра
     * @param name
     * @param value
     */
    saveFilterContent(name, value) {
        let data = this.props.data;
        let row = data.find(item => item.name === name);

        // проверим на наличие полей для фильтрации
        if (!data.length || !row) {
            data = prepareData(this.props.gridConfig, this.props.docTypeId);
        } else {
            data = this.props.data;
        }

        let index,
            isIntervalStart = !!name.match(/_start/),
            isIntervalEnd = !!name.match(/_end/);
        let fieldName = name;

        // надо найти элемент массива с данными для этого компонента
        for (let i = 0; i < data.length; i++) {

            isIntervalStart = !!name.match(/_start/);
            isIntervalEnd = !!name.match(/_end/);

            if (isIntervalStart) {
                // will replace start from firldName
                fieldName = name.replace(/_start/i, '');
            }

            if (isIntervalEnd) {
                // will replace end from firldName
                fieldName = name.replace(/_end/i, '');
            }

            if (data[i].name === (fieldName)) {
                index = i;
                break;
            }
        }

        if (index > -1) {
            if (isIntervalStart) {
                data[index].start = value;
            }
            if (isIntervalEnd) {
                data[index].end = value;
            }

            data[index].value = value;
        }

        // сохраним фильтр
        DocContext.filter[this.props.docTypeId] = data;

        if (this.props.handler) {
            this.props.handler(data);
        }

    }

    componentDidMount() {
        const data = prepareData(this.props.gridConfig, this.props.docTypeId);
        if (this.props.handler) {
            this.props.handler(data);
        }


        // если указан элемент , то установим на него фокус
        if (this.props.focusElement) {
            const focusElement = this.refs[this.props.focusElement];
            if (focusElement) {
                focusElement.focus()
            }
        }
    }

    // will update state if props changed


    static getDerivedStateFromProps(nextProps, prevState) {

        if (JSON.stringify(nextProps.gridConfig) !== JSON.stringify(prevState.gridConfig) ||
            JSON.stringify(nextProps.data) !== JSON.stringify(prevState.data)
            || prevState.data.length === 0 || prevState.data.length !== nextProps.data.length
        ) {
            return {gridConfig: nextProps.gridConfig, data: nextProps.data};
        } else return null;

    }

    render() {
        // создаст из полей грида компоненты для формирования условий фильтрации
        return <div style={styles.fieldset}>
            {this.prepareFilterFields()}
        </div>
    }

    prepareFilterFields() {
        let data = this.props.data;
        // проверим на наличие полей для фильтрации
        if (!data.length) {
            data = prepareData(this.props.gridConfig, this.props.docTypeId);
        }

        let isStateUpdated = false; // if true then will call setState

        // только поля, которые отмечаны как show:true или явно ка указаны и те, у котоых нету hideFilter
        const filterFields = this.props.gridConfig.filter(field => {
            if (field.id !== 'id' && !field.hideFilter && (!field.filter || field.filter == 'show')) {
                return field;
            }
        });

        return filterFields.map((row, index) => {
            let componentType = row.type ? row.type : 'text';

            // ишем дефолтное значение
            let value = row.value ? row.value : '';

            // ищем инициализированное значение
            let obj = data.find(dataRow => dataRow.name == row.id);

            if (obj && ('value' in obj)) {
                console.log('kas value ?, obj, isStateUpdated, value, row ', obj, isStateUpdated, value, row);
                if (!obj.value && value) {
                    // есть дефолтное значение
                    isStateUpdated = true;
                    data = data[index][row.id] = value;
                }
                value = obj.value ? obj.value : value;

            }
            return <div style={styles.formWidget} key={'fieldSet-' + row.id}>
                <div style={styles.formWidgetLabel}>
                    <span>{row.name}</span>
                </div>
                <div style={styles.formWidgetInput}>
                    {row.interval ? this.returnInterval(row)
                        : <input style={styles.input}
                                 type={componentType}
                                 title={row.name}
                                 name={row.id}
                                 placeholder={row.toolTip ? row.toolTip : row.name}
                                 ref={row.id}
                                 value={value || ''}
                                 onChange={this.handleChange}
                                 defaultValue={this.props.data[row.id]}/>
                    }

                </div>
            </div>
        });

    }

    /**
     * вернет два инпута, где будут хранится значения для сначала и конца диапазона
     * @param row
     */
    returnInterval(row) {
        if (row && row.interval && !('start' in row)) {
            let value = row.value ? row.value : null;
            row = {...row, ...{start: value}, ...{end: value}}
        }

        const data = this.props.data;
        let obj = data.find(dataRow => dataRow.name == row.id);

        if (!obj) {
            return null;
        }

        let defaulValue = getDefaultValues(row);
        let valueStart = row.interval ? obj[`start`] : obj.value;
        if (!valueStart) {
            valueStart = defaulValue.start;
        }
        let valueEnd = row.interval ? obj[`end`] : obj.value;
        if (!valueEnd) {
            valueEnd = defaulValue.end;
        }
        let componentType = row.type ? row.type : 'text';
        if (valueStart && valueEnd) {
            // сохраним значение
            this.saveFilterContent(row.name, valueStart);
            this.saveFilterContent(row.name, valueEnd);
        }

        return (
            <div style={styles.interval}>
                <input style={styles.input}
                       type={componentType}
                       title={row.name}
                       name={`${row.id}_start`}
                       placeholder={row.name}
                       ref={`${row.id}_start`}
                       value={valueStart || ''}
                       onChange={this.handleChange}
                       defaultValue={this.props.data[row.id]}
                />
                <span>-</span>
                <input style={styles.input}
                       type={componentType}
                       title={row.name}
                       name={`${row.id}_end`}
                       placeholder={row.name}
                       ref={`${row.id}_end`}
                       value={valueEnd || ''}
                       onChange={this.handleChange}
                       defaultValue={this.props.data[row.id]}
                />
            </div>
        )
    }


}

/*
function prepareData(gridConfig, docTypeId) {
    let data = [];

    if (!DocContext.filter) {
        DocContext.filter = {};
    }

    if (!DocContext.filter[docTypeId]) {
        DocContext.filter[docTypeId] = [];
    }

    // проверим, если фильтр уже сохранен, то вернем уже ранее сохжанный массив
    if (docTypeId && DocContext.filter[docTypeId].length > 0) {
        data = DocContext.filter[docTypeId];
    } else {
        gridConfig.map((row) => {
            let defValue = getDefaultValues(row);
            let start = defValue.start;
            let end = defValue.end;

            const field = {
                value: row.value ? row.value : null,
                name: row.id,
                type: row.type ? row.type : 'text',
                interval: !!row.interval,
                start: row.value ? row.value : start,
                end: row.value ? row.value : end
            };

            data.push(field);

        });
    }

    return data;

}
*/

/**
 * добавит ноль в месяц или день по необходимости
 * @param value
 * @returns {string}
 */
const getTwoDigits = (value) => value < 10 ? `0${value}` : value;


/**
 * вернет дефолтные значения взависимости от типа
 * @param row
 */
const getDefaultValues = (row) => {
    let returnValue = {
        start: null,
        end: null,
        value: null
    };

    Date.prototype.daysInMonth = function () {
        return 33 - new Date(this.getFullYear(), this.getMonth(), 33).getDate();
    };

    let today = new Date();
    let currentMonth = getTwoDigits(today.getMonth() + 1);
    let currentYear = getTwoDigits(today.getFullYear());
    let startMonth = `${currentYear}-${currentMonth}-01`;
    let daysInMonth = getTwoDigits(new Date().daysInMonth());

    let finishMonth = `${currentYear}-${currentMonth}-${daysInMonth}`;

    if (!!row.interval && !row.start && !row.end) {
        switch (row.type) {
            case 'date':
                returnValue.start = startMonth;
                returnValue.end = finishMonth;
                break;
            default:
                returnValue.start = null;
                returnValue.end;
        }
    }
    return returnValue;
};

GridFilter.propTypes = {
    gridConfig: PropTypes.array.isRequired,
    data: PropTypes.array.isRequired
};

module.exports = GridFilter;
