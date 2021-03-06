include $(srcdir)/mk/buildtools.mk

test:
	test "$(CC)" = "$(TEST_CC)"
	test "$(CC_FOR_BUILD)" = "$(TEST_CC_FOR_BUILD)"
	test "$(CXX)" = "$(TEST_CXX)"
	test "$(CXX_FOR_BUILD)" = "$(TEST_CXX_FOR_BUILD)"
	test "$(OBJC)" = "$(TEST_OBJC)"
	test "$(OBJC_FOR_BUILD)" = "$(TEST_OBJC_FOR_BUILD)"
	test "$(OBJCXX)" = "$(TEST_OBJCXX)"
	test "$(OBJCXX_FOR_BUILD)" = "$(TEST_OBJCXX_FOR_BUILD)"
	test "$(GCJ)" = "$(TEST_GCJ)"
	test "$(GCJ_FOR_BUILD)" = "$(TEST_GCJ_FOR_BUILD)"
	test "$(F77)" = "$(TEST_F77)"
	test "$(F77_FOR_BUILD)" = "$(TEST_F77_FOR_BUILD)"
	test "$(FC)" = "$(TEST_FC)"
	test "$(FC_FOR_BUILD)" = "$(TEST_FC_FOR_BUILD)"
	test "$(LD)" = "$(TEST_LD)"
	test "$(LD_FOR_BUILD)" = "$(TEST_LD_FOR_BUILD)"
	test "$(PKG_CONFIG)" = "$(TEST_PKG_CONFIG)"
	test "$(PKG_CONFIG_FOR_BUILD)" = "$(TEST_PKG_CONFIG_FOR_BUILD)"
