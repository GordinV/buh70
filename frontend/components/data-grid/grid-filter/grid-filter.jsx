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
        this.forceUpdate();
    }

    /**
     * сохранит значение фильтра
     * @param name
     * @param value
     */
    saveFilterContent(name, value) {
        let data = this.props.data;

        // проверим на наличие полей для фильтрации
        if (!data.length || !row) {
            data = prepareData(this.props.gridConfig, this.props.docTypeId);
        } else {
            data = this.props.data;
        }

        // сохраним значение фильтра
        let row = data.map(row => {
            if (row.id === name) {
                row.value = value;
                return row;
            }
        });

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

            if (data[i].id === (fieldName)) {
                index = i;
                break;
            }

        }

        if (index > -1) {
            if (isIntervalStart) {
                data[index].start = value;
                data[index][`${fieldName}_start`] = value;
            }
            if (isIntervalEnd) {
                data[index].end = value;
                data[index][`${fieldName}_end`] = value;
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
            let obj = data.find(dataRow => dataRow.id == row.id);

            if (obj && ('value' in obj)) {
                if (!obj.value && value) {
                    // есть дефолтное значение
                    isStateUpdated = true;
                    value = data[index][row.id].value;
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
        let obj = data.find(dataRow => dataRow.id == row.id);

        if (!obj) {
            return null;
        }

        let valueStart = row.interval ? obj[`start`] : obj.value;
        let valueEnd = row.interval ? obj[`end`] : obj.value;

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


GridFilter.propTypes = {
    gridConfig: PropTypes.array.isRequired,
    data: PropTypes.array.isRequired
};

module.exports = GridFilter;
