'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./grid-filter-styles');

const _ = require('lodash');

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
     * @param e
     */
    handleChange(e) {
        let data = this.state.data;

        // проверим на наличие полей для фильтрации
        if (!data.length) {
            data = prepareData(this.props.gridConfig);
        }

        let value = e.target.value,
            id = e.target.name,
            index,
            isIntervalStart = !!id.match(/_start/),
            isIntervalEnd = !!id.match(/_end/);
        let fieldName = id;

        // надо найти элемент массива с данными для этого компонента
        for (let i = 0; i < this.state.data.length; i++) {

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

            if (this.state.data[i].name === (fieldName)) {
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

        if (this.props.handler) {
            this.props.handler(data);
        }
        this.forceUpdate();

    }

    componentDidMount() {
        const data = prepareData(this.props.gridConfig);
        if (this.props.handler) {
            this.props.handler(data);
        }
    }

    // will update state if props changed

    static getDerivedStateFromProps(nextProps, prevState) {

        if (JSON.stringify(nextProps.gridConfig) !== JSON.stringify(prevState.gridConfig) ||
            JSON.stringify(nextProps.data) !== JSON.stringify(prevState.data)
            || prevState.data.length === 0
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
        let data = this.state.data;
        let isStateUpdated = false; // if true then will call setState

        // только поля, которые отмечаны как show:true или явно ка указаны
        const filterFields = this.state.gridConfig.filter(field => {
            if (field.id !== 'id' && (!field.filter || field.filter == 'show')) {
                return field;
            }
        });

        return filterFields.map((row, index) => {
            let componentType = row.type ? row.type : 'text';

            // ишем дефолтное значение
            let value = row.value ? row.value : '';

            // ищем инициализированное значение
            const obj = data[_.findIndex(data, {name: row.id})];

            if (_.has(obj, 'value')) {
                if (!obj.value && value) {
                    // есть дефолтное значение
                    isStateUpdated = true;
                    data = data[index][row.id] = value;
                }
                value = obj.value ? obj.value : value
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
        if (row.interval && !('start' in row)) {
            let value = row.value ? row.value: null;
            row = {...row, ...{start: value}, ...{end: value}}
        }

        const data = this.state.data;
        const obj = data[_.findIndex(data, {name: row.id})];

        let valueStart = row.interval ? obj[`start`] : obj.value;
        let valueEnd = row.interval ? obj[`end`] : obj.value;

        let componentType = row.type ? row.type : 'text';

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

function prepareData(gridConfig) {
    const data = [];

    gridConfig.map((row) => {
        const field = {
            value: row.value ? row.value : null,
            name: row.id,
            type: row.type ? row.type : 'text',
            interval: !!row.interval,
            start: row.value ? row.value: null,
            end: row.value ? row.value: null
        };

        data.push(field);

    });
    return data;

}


GridFilter.propTypes = {
    gridConfig: PropTypes.array.isRequired,
    data: PropTypes.array.isRequired
};

module.exports = GridFilter;
