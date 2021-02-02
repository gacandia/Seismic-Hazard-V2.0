import numpy as np
import sys
repo_path = '../'
sys.path.append(repo_path)
import pyHMRF

# ******************************************************************************************************************
"""   TEST 1-DIMENSIONAL DATA   """
# test 1D with 2 feature;   1d_data[Y,F]
data_1d_1 = np.genfromtxt('../test_data/test_data_1d_1.csv', delimiter=',')
data_1d_2 = np.genfromtxt('../test_data/test_data_1d_2.csv', delimiter=',')
coord_1d = np.genfromtxt('../test_data/coord_1d.csv', delimiter=',')

data = np.stack((data_1d_1, data_1d_2), axis=1)
my_hmrf = pyHMRF.Element(data, coord_1d)

print('phys_shp:  ' + str(my_hmrf.phys_shp))
print('n_feat:  ' + str(my_hmrf.n_feat))

my_hmrf.fit(num_of_iter=100, n_labels=3, beta_jump_length=0.1)

# *********************************************************************************************************************
"""  TEST 2-DIMENSIONAL DATA  """
# test 2D data with 2 features;  2d_data[Y,X,F]  (Y,X) = (5,5)
data_1 = np.genfromtxt('../test_data/test_data_1.csv', delimiter=',')
data_2 = np.genfromtxt('../test_data/test_data_2.csv', delimiter=',')
coord = np.genfromtxt('../test_data/coord.csv', delimiter=',')

data = np.stack((data_1, data_2), axis=2)  # convert data_shape to [Y,X,F], here is (5,5,2)

my_hmrf = pyHMRF.Element(data, coord)
print('phys_shp:  ' + str(my_hmrf.phys_shp))
print('n_feat:  ' + str(my_hmrf.n_feat))

my_hmrf.fit(num_of_iter=100, n_labels=3, beta_jump_length=0.1)


# *********************************************************************************************************
# test with synthetic data, same as above example
data_1 = np.genfromtxt('../test_data/feature_1.csv', delimiter=',')
data_2 = np.genfromtxt('../test_data/feature_2.csv', delimiter=',')
coord = np.genfromtxt('../test_data/physic_coord.csv', delimiter=',')

data = np.stack((data_1, data_2), axis=2)

my_hmrf = pyHMRF.Element(data, coord)
print('phys_shp:  ' + str(my_hmrf.phys_shp))
print('n_feat:  ' + str(my_hmrf.n_feat))

# fit the model: 100 iterations and beta_jump = 0.1
my_hmrf.fit(num_of_iter=200, n_labels=3, beta_init=[0.5, 0.5, 0.5, 0.5], beta_jump_length=0.1)

print("beta_list:  ")
start = 100

print(np.asmatrix(my_hmrf.betas[start:]))
print("beta_mean: ", np.mean(np.asmatrix(my_hmrf.betas[start:]), axis=0))  # use mean beta as estimate
print("beta_std: ", np.std(np.asmatrix(my_hmrf.betas[start:]), axis=0))
