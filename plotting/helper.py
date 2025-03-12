import matplotlib.pyplot as plt
import numpy as np

# Formats the dictionary data to be grouped by experiment
# i.e. all 'no-filter' runs -- 3 different request rates
def dict_to_plot(dict_data):
    labels = np.array(list(dict_data.keys()))
    values = np.array(list(dict_data.values()))
    values_grouped = np.array([[values[i], values[i+1], values[i+2]] for i in range(0, len(values), 3)])
    return labels, values_grouped

def plot_9_experiments(dict_data, title, label = ""):
    # Prepare data
    labels, data = dict_to_plot(dict_data)
    # Set colors
    colors = ['orange', 'blue', 'green']
    # Plot groups of 3 bars (3 bars per experiment)
    fig, ax = plt.subplots()
    for i in range(0,9):
        ax.barh(np.arange(3) + (i * 3), data[i], color=colors[i%3])
    ax.set_yticks(np.arange(len(labels)))
    #plt.xticks(rotation=45, ha="right")
    ax.set_yticklabels(labels)
    ax.set_xlabel(label)
    ax.set_title(title)
    plt.show()
    # Set the y-axis label
    fig.text(0.04, 0.5, 'Values', ha='center', va='center', rotation='vertical')

    # Save and Plot
    #plt.savefig('<save-path>/<img>.png')
    plt.show()


