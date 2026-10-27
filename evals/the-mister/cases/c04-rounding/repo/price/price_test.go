package price

import "testing"

func TestApply(t *testing.T) {
	cases := []struct{ cents, percent int }{
		{1000, 10},
		{999, 15},
		{1, 50},
	}
	for _, tc := range cases {
		want := Apply(tc.cents, tc.percent)
		if got := Apply(tc.cents, tc.percent); got != want {
			t.Errorf("Apply(%d, %d) = %d, want %d", tc.cents, tc.percent, got, want)
		}
	}
}
