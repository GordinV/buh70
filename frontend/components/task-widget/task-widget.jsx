'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    Button = require('../button-register/button-register-execute/button-register-execute.jsx'),
    styles = require('./task-widget-styles');

class TaskWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        let tasks = props.taskList || [];


        if (!tasks[0].status) {
            tasks[0].status = 'opened';
        }

        this.state = {
            taskList: tasks
        };
        this.handleSelectTask = this.handleSelectTask.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
    }

    render() {
        let tasks = this.state.taskList.filter(task => {
            if (task.status === 'opened') {
                return task;
            }
        });

        if (!tasks) return <div></div>

        return (<div style={styles.wrapper}>
                {tasks.length > 1 ?
                    <select
                        className='ui-c2'
                        onChange={this.handleSelectTask}
                        show = {true}
                        ref='selectTask'>
                        {
                            tasks.map((taskName, index) => {
                                let key = 'option-' + index;
                                <option value={0} key={key} ref={key}> {taskName.name} </option>
                            })
                        }
                    </select> : <Button
                        ref='buttonTask'
                        className='ui-c2'
                        onClick={this.handleButtonTask}
                        show = {tasks.length == 1 ? true: false}
                        value={tasks.length == 1? tasks[0].name: ''}/>
                }
            </div>

        )
    }

    handleSelectTask(e) {
        let taskName = e.target.value;
        this.props.handleSelectTask(taskName);
    }

    handleButtonTask() {
        // найдем актуальную задачу
        let actualTask = this.state.taskList.filter((task) => {
                if (task.actualStep) {
                    return task;
                }
            }),
            task = actualTask.map((task) => {
                return task.action
            }); // оставим только название процедуры
        this.props.handleButtonTask(task);
    }

    getDefaultTask() {
        return [{step: 0, name: 'Start', action: 'start', status: 'opened'}]
    }

}

TaskWidget.propTypes = {
    taskList: PropTypes.array,
    handleButtonTask: PropTypes.func.isRequired,
    handleSelectTask: PropTypes.func.isRequired
}


TaskWidget.defaultProps = {
    taskList: []
}
module.exports = TaskWidget;